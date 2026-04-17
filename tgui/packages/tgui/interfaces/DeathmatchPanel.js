import { useBackend } from '../backend';
import { Box, Button, Flex, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';

export const DeathmatchPanel = (props, context) => {
  const { data } = useBackend(context);
  return (
    <Window title="Дезматч" width={500} height={420}>
      <Window.Content>
        <Stack fill vertical>
          {!data.in_lobby ? <DeathmatchBrowser /> : <DeathmatchLobby />}
        </Stack>
      </Window.Content>
    </Window>
  );
};

const DeathmatchBrowser = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Stack fill vertical>
      {data.active?.length > 0 && (
        <Stack.Item>
          <Section title="Идут матчи">
            {data.active.map((lobby) => (
              <Stack key={lobby.host} className="candystripe" p={1} align="center">
                <Stack.Item grow>
                  <Box bold>{lobby.host}</Box>
                  <Box color="label" fontSize="11px">Карта: {lobby.map} · {lobby.players} игроков</Box>
                </Stack.Item>
                <Stack.Item>
                  <Button icon="eye" content="Наблюдать" onClick={() => act('spectate', { ref: lobby.ref })} />
                </Stack.Item>
              </Stack>
            ))}
          </Section>
        </Stack.Item>
      )}
      <Stack.Item grow>
        <Section
          fill
          scrollable
          title="Лобби"
          buttons={
            <Button icon="plus" content="Создать лобби" color="good" onClick={() => act('create_lobby')} />
          }>
          {(!data.lobbies || !data.lobbies.length) && (
            <NoticeBox info>Нет открытых лобби. Создайте своё!</NoticeBox>
          )}
          {data.lobbies?.map((lobby) => (
            <Stack key={lobby.host} className="candystripe" p={1} align="center">
              <Stack.Item grow>
                <Box bold>{lobby.host}</Box>
                <Box color="label" fontSize="11px">Карта: {lobby.map}</Box>
              </Stack.Item>
              <Stack.Item>{lobby.players}/{lobby.max_players || '?'}</Stack.Item>
              <Stack.Item>
                <Button icon="sign-in-alt" content="Войти" onClick={() => act('join_lobby', { ref: lobby.ref })} />
              </Stack.Item>
            </Stack>
          ))}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const DeathmatchLobby = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Stack fill vertical>
      <Stack.Item>
        <Section
          title={'Лобби: ' + data.lobby_host}
          buttons={
            <>
              <Button
                icon={data.my_ready ? 'check-circle' : 'circle'}
                content={data.my_ready ? 'Готов' : 'Не готов'}
                color={data.my_ready ? 'good' : 'average'}
                onClick={() => act('toggle_ready')}
              />
              <Button icon="sign-out-alt" content="Выйти" color="bad" onClick={() => act('leave_lobby')} />
            </>
          }>
          <Box color="label">Карта: <Box inline bold color="white">{data.lobby_map}</Box></Box>
        </Section>
      </Stack.Item>

      <Stack.Item grow>
        <Section fill scrollable title="Игроки">
          {data.lobby_players?.map((player) => (
            <Stack key={player.ckey} className="candystripe" p={1} align="center">
              <Stack.Item grow>
                <Box inline bold>{player.ckey}</Box>
                {player.is_host && <Box inline color="yellow" ml={1}>хост</Box>}
              </Stack.Item>
              <Stack.Item color="label">{player.loadout}</Stack.Item>
              <Stack.Item color={player.ready ? 'green' : 'red'} minWidth="24px" textAlign="center">
                {player.ready ? '✔' : '✘'}
              </Stack.Item>
            </Stack>
          ))}
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section title={'Лоадаут: ' + (data.my_loadout || 'Не выбран')}>
          <Flex wrap="wrap">
            {data.loadouts?.map((lo) => (
              <Flex.Item key={lo.ref} m={0.5}>
                <Button
                  selected={data.my_loadout === lo.name}
                  tooltip={lo.desc}
                  content={lo.name}
                  onClick={() => act('set_loadout', { ref: lo.ref })}
                />
              </Flex.Item>
            ))}
          </Flex>
        </Section>
      </Stack.Item>

      {data.is_host && (
        <>
          <Stack.Item>
            <Section title="Выбор карты">
              <Flex wrap="wrap">
                {data.maps?.map((map) => (
                  <Flex.Item key={map.ref} m={0.5}>
                    <Button
                      selected={data.lobby_map === map.name}
                      tooltip={map.desc + ' (макс. ' + map.max_players + ' игроков)'}
                      content={map.name}
                      onClick={() => act('set_map', { ref: map.ref })}
                    />
                  </Flex.Item>
                ))}
              </Flex>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Button
              fluid
              icon="play"
              content="НАЧАТЬ МАТЧ"
              color="good"
              fontSize="14px"
              textAlign="center"
              onClick={() => act('start_game')}
            />
          </Stack.Item>
        </>
      )}
    </Stack>
  );
};
