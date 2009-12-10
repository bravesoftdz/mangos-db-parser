object MainDataModule: TMainDataModule
  OldCreateOrder = False
  Height = 128
  Width = 120
  object connSRC: TMyConnection
    Database = 'w_world_udb'
    Options.UseUnicode = True
    Options.Charset = 'utf8'
    Username = 'soar'
    Password = 'knfdptsn32'
    Server = '10.10.0.39'
    Connected = True
    LoginPrompt = False
    Left = 14
    Top = 14
  end
  object connDST: TMyConnection
    Database = 'w_world_ytdb'
    Options.UseUnicode = True
    Options.Charset = 'utf8'
    Username = 'soar'
    Password = 'knfdptsn32'
    Server = '10.10.0.39'
    Connected = True
    LoginPrompt = False
    Left = 66
    Top = 14
  end
  object tSRC: TMyTable
    Connection = connSRC
    FetchRows = 100
    CachedUpdates = True
    Left = 14
    Top = 64
  end
  object tDST: TMyTable
    Connection = connDST
    Left = 66
    Top = 64
  end
end
