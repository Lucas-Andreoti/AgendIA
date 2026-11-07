# AgendIA

Aplicativo desenvolvido em Flutter e Dart como parte do Trabalho de
Conclusão de Curso de Ciência da Computação.

O AgendIA permite que uma profissional de beleza gerencie sua agenda.
A solução completa integra o aplicativo a um atendimento automatizado
pelo Telegram, utilizando fluxos n8n e inteligência artificial.

## Funcionalidades principais

- Login e saída da conta.
- Consulta da agenda por data.
- Visualização do próximo agendamento.
- Consulta, edição e cancelamento de agendamentos.
- Gerenciamento de serviços.
- Configuração do expediente.

## Conteúdo deste repositório

Este repositório contém o código do aplicativo Flutter e sua configuração
para Android. A API, o banco de dados e os fluxos n8n são componentes
externos e não estão incluídos neste repositório.

## Como executar

É necessário ter Flutter, o ambiente de desenvolvimento Android
e um dispositivo ou emulador configurados.

1. Clone ou baixe este repositório.
2. Abra um terminal na pasta que contém o arquivo pubspec.yaml.
3. Instale as dependências:

```bash
flutter pub get
```

4. Confira a configuração do endereço da API utilizado pelo aplicativo.
5. Com um dispositivo Android conectado ou emulador aberto, execute:

```bash
flutter run
```

O funcionamento integrado depende da disponibilidade da API e dos
serviços externos. Baixar o aplicativo não inicia esses serviços.

## Observações

- Quando um agendamento é alterado ou cancelado pelo aplicativo,
  a profissional deve comunicar a cliente manualmente.
- O bloqueio de horários está previsto, mas não foi implementado
  nesta versão.
- Projeto desenvolvido para fins acadêmicos.
