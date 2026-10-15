# The Vanilla VR launcher: a window in the manner of the old game launcher (the news, your realm,
# a progress bar, a big Play button) over play.ps1, which does the work: your settings, the update
# (from your friend's PC, or from GitHub when you play solo; only what changed, every file checked,
# the old copies kept), going back a version, your logs to your friend, your own realm (solo.ps1),
# starting the game and, when it closes, asking how it went. Once your game folder is set it wears
# your game's own login-screen art (the logo, the red buttons, the gold frames, the fonts), read
# from your install by launcher-art.exe into cache\launcher\; nothing of the game's ships with the
# kit. Without WPF it opens the console one.
# -Snapshot <png> draws the window to a picture and exits (-Look plain|wow picks the look); -Demo
# fills it with an update under way, and -Page settings, rollback, feedback, build or ready shows
# that state (for the guide and for checking the look). -CheckOnly runs the window's check (the
# server, the update, the logs) with no window and prints what it reported, for the tests.
# -AutoPlay presses Play once the first check is done (a test with a stand-in game).
param([string]$Snapshot, [switch]$Demo, [string]$Page = '', [string]$Look = '', [switch]$CheckOnly, [switch]$AutoPlay)

$ErrorActionPreference = 'Stop'
$kitDir = $PSScriptRoot
try {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
} catch {
    Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-NoExit',
        '-File', "`"$(Join-Path $kitDir 'play.ps1')`""
    return
}
. (Join-Path $kitDir 'play.ps1') -Library

$controlsUrl = 'https://claude.ai/artifact/JvCN7hMaJAwirPu6VZmg2J'
# The game's art, read from your install (launcher-art.exe): this set's version.
$artDir = Join-Path $kitDir 'cache\launcher'
$artVersion = 1

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:sys="clr-namespace:System;assembly=mscorlib"
        Title="Vanilla VR" Width="940" Height="600" WindowStyle="None" ResizeMode="CanMinimize"
        WindowStartupLocation="CenterScreen" Background="#0E0A07" UseLayoutRounding="True"
        TextOptions.TextFormattingMode="Ideal" FontFamily="{DynamicResource BodyFont}"
        RenderOptions.BitmapScalingMode="HighQuality">
  <Window.Resources>
    <FontFamily x:Key="Serif">Palatino Linotype, Book Antiqua, Georgia, serif</FontFamily>
    <FontFamily x:Key="BodyFont">Segoe UI</FontFamily>
    <FontFamily x:Key="FieldFont">Segoe UI</FontFamily>
    <FontFamily x:Key="MarkFont">Palatino Linotype, Georgia, serif</FontFamily>
    <sys:Double x:Key="BarHeight">18</sys:Double>
    <LinearGradientBrush x:Key="Gold" StartPoint="0,0" EndPoint="0,1">
      <GradientStop Color="#FFF1B8" Offset="0"/>
      <GradientStop Color="#E2B44D" Offset="0.42"/>
      <GradientStop Color="#B8862E" Offset="0.62"/>
      <GradientStop Color="#7A5216" Offset="1"/>
    </LinearGradientBrush>
    <LinearGradientBrush x:Key="GoldEdge" StartPoint="0,0" EndPoint="1,1">
      <GradientStop Color="#FFF1B8" Offset="0"/>
      <GradientStop Color="#E2B44D" Offset="0.25"/>
      <GradientStop Color="#6E4A14" Offset="0.5"/>
      <GradientStop Color="#B8862E" Offset="0.75"/>
      <GradientStop Color="#FFF1B8" Offset="1"/>
    </LinearGradientBrush>
    <SolidColorBrush x:Key="WindowEdge" Color="#B8862E"/>
    <SolidColorBrush x:Key="Parch" Color="#EADBB8"/>
    <SolidColorBrush x:Key="ParchDim" Color="#B8A37C"/>
    <SolidColorBrush x:Key="PanelFill" Color="#B3130D08"/>
    <SolidColorBrush x:Key="PanelEdge" Color="#7A5A22"/>
    <SolidColorBrush x:Key="DialogFill" Color="#1E150D"/>
    <DropShadowEffect x:Key="Outline" Color="#000000" BlurRadius="4" ShadowDepth="1.5" Opacity="0.95"/>

    <Style x:Key="Heading" TargetType="TextBlock">
      <Setter Property="FontFamily" Value="{DynamicResource Serif}"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="Foreground" Value="{DynamicResource Gold}"/>
    </Style>
    <Style x:Key="Body" TargetType="TextBlock">
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="Foreground" Value="{DynamicResource Parch}"/>
      <Setter Property="TextWrapping" Value="Wrap"/>
    </Style>
    <Style x:Key="Small" TargetType="TextBlock" BasedOn="{StaticResource Body}">
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Foreground" Value="{DynamicResource ParchDim}"/>
    </Style>

    <Style x:Key="Panel" TargetType="ContentControl">
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ContentControl">
            <Border Background="{DynamicResource PanelFill}" BorderBrush="{DynamicResource PanelEdge}" BorderThickness="1" CornerRadius="4">
              <ContentPresenter/>
            </Border>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Dialog" TargetType="ContentControl">
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ContentControl">
            <Border Background="{DynamicResource DialogFill}" BorderBrush="{DynamicResource GoldEdge}" BorderThickness="2" CornerRadius="5" Padding="26,16,26,20">
              <DockPanel>
                <TextBlock DockPanel.Dock="Top" Text="{Binding Tag, RelativeSource={RelativeSource TemplatedParent}}"
                           Style="{DynamicResource Heading}" FontSize="18" Margin="0,0,0,12"/>
                <ContentPresenter/>
              </DockPanel>
            </Border>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="GoldButton" TargetType="Button">
      <Setter Property="Foreground" Value="{DynamicResource Parch}"/>
      <Setter Property="FontFamily" Value="{DynamicResource Serif}"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="Height" Value="34"/>
      <Setter Property="Padding" Value="14,0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="B" CornerRadius="3" BorderThickness="1.5" BorderBrush="{DynamicResource GoldEdge}"
                    Padding="{TemplateBinding Padding}">
              <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                  <GradientStop Color="#3C2B19" Offset="0"/>
                  <GradientStop Color="#1C130B" Offset="1"/>
                </LinearGradientBrush>
              </Border.Background>
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="B" Property="Background" Value="#523A1E"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="B" Property="Background" Value="#2A1D10"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter TargetName="B" Property="Opacity" Value="0.38"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="ChromeButton" TargetType="Button">
      <Setter Property="Foreground" Value="{DynamicResource ParchDim}"/>
      <Setter Property="FontSize" Value="15"/>
      <Setter Property="Width" Value="34"/>
      <Setter Property="Height" Value="28"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="B" Background="Transparent" CornerRadius="3">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="B" Property="Background" Value="#33E2B44D"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="MinButton" TargetType="Button" BasedOn="{StaticResource ChromeButton}">
      <Setter Property="Content" Value="&#x2013;"/>
    </Style>
    <Style x:Key="CloseButton" TargetType="Button" BasedOn="{StaticResource ChromeButton}">
      <Setter Property="Content" Value="&#x2715;"/>
    </Style>

    <Style x:Key="PlayButton" TargetType="Button">
      <Setter Property="Foreground" Value="#FFF4D6"/>
      <Setter Property="FontFamily" Value="{DynamicResource Serif}"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="FontSize" Value="30"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Grid>
              <Border x:Name="Glow" CornerRadius="6" Margin="-6" Background="#00E2B44D">
                <Border.Effect><BlurEffect Radius="14"/></Border.Effect>
              </Border>
              <Border x:Name="Frame" CornerRadius="5" BorderThickness="3" BorderBrush="{DynamicResource GoldEdge}">
                <Border x:Name="Face" CornerRadius="3" BorderThickness="1" BorderBrush="#40000000">
                  <Border.Background>
                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                      <GradientStop Color="#D2452A" Offset="0"/>
                      <GradientStop Color="#9C2414" Offset="0.48"/>
                      <GradientStop Color="#6E140A" Offset="0.52"/>
                      <GradientStop Color="#8E1E10" Offset="1"/>
                    </LinearGradientBrush>
                  </Border.Background>
                  <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center">
                    <ContentPresenter.Effect><DropShadowEffect Color="#000000" BlurRadius="4" ShadowDepth="2" Opacity="0.9"/></ContentPresenter.Effect>
                  </ContentPresenter>
                </Border>
              </Border>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Glow" Property="Background" Value="#99F0C060"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="Face" Property="Opacity" Value="0.8"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter TargetName="Face" Property="Background" Value="#4A3A2C"/>
                <Setter Property="Foreground" Value="#A8987C"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Field" TargetType="TextBox">
      <Setter Property="Background" Value="#120C07"/>
      <Setter Property="Foreground" Value="{DynamicResource Parch}"/>
      <Setter Property="CaretBrush" Value="{DynamicResource Parch}"/>
      <Setter Property="BorderBrush" Value="#8A6A2A"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="6,5"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontFamily" Value="{DynamicResource FieldFont}"/>
      <Setter Property="VerticalContentAlignment" Value="Center"/>
    </Style>
    <Style x:Key="Check" TargetType="CheckBox">
      <Setter Property="Foreground" Value="{DynamicResource Parch}"/>
      <Setter Property="FontSize" Value="13"/>
    </Style>
    <Style x:Key="Pick" TargetType="RadioButton">
      <Setter Property="Foreground" Value="{DynamicResource Parch}"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="VerticalAlignment" Value="Center"/>
      <Setter Property="Margin" Value="0,0,12,0"/>
    </Style>

    <Style x:Key="GoldBar" TargetType="ProgressBar">
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ProgressBar">
            <Border CornerRadius="3" BorderThickness="1" BorderBrush="#8A6A2A" Background="#0A0705" Padding="2">
              <Grid x:Name="PART_Track">
                <Border x:Name="PART_Indicator" HorizontalAlignment="Left" CornerRadius="2">
                  <Border.Background>
                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                      <GradientStop Color="#FFF1B8" Offset="0"/>
                      <GradientStop Color="#E2B44D" Offset="0.45"/>
                      <GradientStop Color="#9A6A1E" Offset="1"/>
                    </LinearGradientBrush>
                  </Border.Background>
                </Border>
              </Grid>
            </Border>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Border BorderThickness="2" BorderBrush="{DynamicResource WindowEdge}">
    <Grid x:Name="Root" ClipToBounds="True">
      <Grid.Background>
        <RadialGradientBrush Center="0.3,0" GradientOrigin="0.3,0" RadiusX="1.1" RadiusY="1.3">
          <GradientStop Color="#33261A" Offset="0"/>
          <GradientStop Color="#1A130D" Offset="0.45"/>
          <GradientStop Color="#0B0806" Offset="1"/>
        </RadialGradientBrush>
      </Grid.Background>
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="20"/>
        <ColumnDefinition Width="430"/>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="300"/>
        <ColumnDefinition Width="20"/>
      </Grid.ColumnDefinitions>
      <Grid.RowDefinitions>
        <RowDefinition Height="20"/>
        <RowDefinition Height="170"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="96"/>
        <RowDefinition Height="6"/>
      </Grid.RowDefinitions>

      <!-- The game's look: a loading screen behind everything, darker where the words are. -->
      <Image x:Name="Backdrop" Grid.RowSpan="5" Grid.ColumnSpan="5" Width="936" Height="702" Stretch="Fill"
             HorizontalAlignment="Left" VerticalAlignment="Top" Visibility="Collapsed"/>
      <Rectangle x:Name="Shade" Grid.RowSpan="5" Grid.ColumnSpan="5" Visibility="Collapsed">
        <Rectangle.Fill>
          <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
            <GradientStop Color="#00000000" Offset="0"/>
            <GradientStop Color="#22000000" Offset="0.5"/>
            <GradientStop Color="#D0000000" Offset="1"/>
          </LinearGradientBrush>
        </Rectangle.Fill>
      </Rectangle>

      <StackPanel x:Name="Brand" Grid.Row="1" Grid.Column="2" Grid.ColumnSpan="2" Orientation="Horizontal"
                  HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,4,0">
        <Viewbox x:Name="Crest" Width="78" Height="78">
          <Canvas Width="64" Height="64">
            <Path Data="M9 56 55 6M55 56 9 6" Stroke="#3A2208" StrokeThickness="6" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
            <Path Data="M9 56 55 6M55 56 9 6" Stroke="{DynamicResource Gold}" StrokeThickness="3.2" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
            <Path Data="M7 47 18 58M57 47 46 58" Stroke="#3A2208" StrokeThickness="5.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
            <Path Data="M7 47 18 58M57 47 46 58" Stroke="{DynamicResource Gold}" StrokeThickness="3" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
            <Path Data="M32 14c9 4 16 4 20 3 0 22-8 34-20 42C20 51 12 39 12 17c4 1 11 1 20-3z" Fill="#7A2410" Stroke="#3A2208" StrokeThickness="2.5"/>
            <Path Data="M32 18c7 3 12 3 16 3-1 17-7 27-16 33-9-6-15-16-16-33 4 0 9 0 16-3z" Stroke="{DynamicResource Gold}" StrokeThickness="2"/>
            <Path Data="M32 26l3 7h7l-5.5 4.5 2 7.5L32 40.5 25.5 45l2-7.5L22 33h7z" Fill="{DynamicResource Gold}" Stroke="#3A2208" StrokeThickness="1"/>
          </Canvas>
        </Viewbox>
        <StackPanel Margin="12,0,0,0" VerticalAlignment="Center">
          <TextBlock Text="Vanilla VR" FontFamily="{DynamicResource Serif}" FontWeight="Bold" FontSize="44"
                     Foreground="{DynamicResource Gold}" Effect="{StaticResource Outline}"/>
          <TextBlock Text="The 1.12 world, in virtual reality" FontFamily="{DynamicResource Serif}" FontStyle="Italic"
                     FontSize="15" Foreground="{DynamicResource ParchDim}" Margin="3,-4,0,0"/>
        </StackPanel>
      </StackPanel>
      <!-- Beneath the game's own logo, which the loading screen carries. -->
      <TextBlock x:Name="VrMark" Grid.Row="1" Grid.Column="3" Text="VR" FontFamily="{DynamicResource MarkFont}" FontSize="50"
                 HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,10,-6" Visibility="Collapsed">
        <TextBlock.Foreground>
          <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
            <GradientStop Color="#FFF6C8" Offset="0"/>
            <GradientStop Color="#F2C45A" Offset="0.45"/>
            <GradientStop Color="#B07A22" Offset="0.7"/>
            <GradientStop Color="#6E4A14" Offset="1"/>
          </LinearGradientBrush>
        </TextBlock.Foreground>
        <TextBlock.Effect><DropShadowEffect Color="#000000" BlurRadius="5" ShadowDepth="2" Opacity="1"/></TextBlock.Effect>
      </TextBlock>

      <ContentControl Grid.Row="1" Grid.RowSpan="2" Grid.Column="1" Style="{DynamicResource Panel}" Margin="0,0,0,10">
        <DockPanel Margin="20,16,10,16">
          <TextBlock DockPanel.Dock="Top" Text="NEWS" Style="{DynamicResource Heading}" FontSize="18" Margin="0,0,0,10"/>
          <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="0,0,10,0">
            <ScrollViewer.Resources>
              <Style TargetType="ScrollBar">
                <Setter Property="Width" Value="8"/>
                <Setter Property="MinWidth" Value="8"/>
                <Setter Property="Template">
                  <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                      <Track x:Name="PART_Track" IsDirectionReversed="True">
                        <Track.Thumb>
                          <Thumb>
                            <Thumb.Template>
                              <ControlTemplate TargetType="Thumb">
                                <Border CornerRadius="3" Background="#90B8862E"/>
                              </ControlTemplate>
                            </Thumb.Template>
                          </Thumb>
                        </Track.Thumb>
                      </Track>
                    </ControlTemplate>
                  </Setter.Value>
                </Setter>
              </Style>
            </ScrollViewer.Resources>
            <StackPanel x:Name="NewsList"/>
          </ScrollViewer>
        </DockPanel>
      </ContentControl>

      <StackPanel Grid.Row="2" Grid.Column="3" Margin="0,4,0,0">
        <ContentControl Style="{DynamicResource Panel}">
          <Grid Margin="18,14,16,14">
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="80"/>
              <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock Text="REALM" Style="{DynamicResource Heading}" Margin="0,1,0,0"/>
            <DockPanel Grid.Column="1">
              <Ellipse x:Name="RealmDot" DockPanel.Dock="Left" Width="10" Height="10" Fill="#7A7060" Margin="0,4,7,0" VerticalAlignment="Top"/>
              <TextBlock x:Name="RealmText" Style="{DynamicResource Body}" FontSize="13" Text="Looking..."/>
            </DockPanel>
            <TextBlock x:Name="ServerText" Grid.Row="1" Grid.Column="1" Style="{DynamicResource Small}" Margin="17,1,0,0"/>
            <TextBlock Grid.Row="2" Text="VERSION" Style="{DynamicResource Heading}" Margin="0,9,0,0"/>
            <TextBlock x:Name="VersionText" Grid.Row="2" Grid.Column="1" Style="{DynamicResource Body}" FontSize="13" Margin="0,9,0,0"/>
            <TextBlock Grid.Row="3" Text="HEADSET" Style="{DynamicResource Heading}" Margin="0,9,0,0"/>
            <DockPanel Grid.Row="3" Grid.Column="1" Margin="0,9,0,0">
              <Ellipse x:Name="VrDot" DockPanel.Dock="Left" Width="10" Height="10" Fill="#7A7060" Margin="0,4,7,0" VerticalAlignment="Top"/>
              <TextBlock x:Name="VrText" Style="{DynamicResource Body}" FontSize="13"/>
            </DockPanel>
          </Grid>
        </ContentControl>
        <UniformGrid Columns="2" Margin="0,10,0,0">
          <Button x:Name="SettingsBtn" Content="Settings" Style="{DynamicResource GoldButton}" Margin="0,0,5,6"/>
          <Button x:Name="ControlsBtn" Content="Controls" Style="{DynamicResource GoldButton}" Margin="5,0,0,6"/>
          <Button x:Name="FeedbackBtn" Content="Feedback" Style="{DynamicResource GoldButton}" Margin="0,0,5,6"/>
          <Button x:Name="LogsBtn" Content="Logs" Style="{DynamicResource GoldButton}" Margin="5,0,0,6"/>
        </UniformGrid>
        <Button x:Name="RollbackBtn" Content="Go back a version" Style="{DynamicResource GoldButton}" Width="190" HorizontalAlignment="Center"/>
      </StackPanel>

      <StackPanel Grid.Row="3" Grid.Column="1" Grid.ColumnSpan="2" VerticalAlignment="Center" Margin="0,0,24,0">
        <TextBlock x:Name="StatusText" Style="{DynamicResource Body}" TextWrapping="NoWrap" TextTrimming="CharacterEllipsis" Margin="2,0,0,6"/>
        <ProgressBar x:Name="Progress" Height="{DynamicResource BarHeight}" Minimum="0" Maximum="1" Value="0" Style="{DynamicResource GoldBar}"/>
      </StackPanel>
      <Button x:Name="PlayBtn" Grid.Row="3" Grid.Column="3" Content="PLAY" Style="{DynamicResource PlayButton}" Width="240" Height="64"
              HorizontalAlignment="Right" VerticalAlignment="Center"/>

      <StackPanel Grid.RowSpan="5" Grid.ColumnSpan="5" Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Top"
                  Margin="0,4,6,0" Panel.ZIndex="5">
        <Button x:Name="MinBtn" Style="{DynamicResource MinButton}" ToolTip="Minimise"/>
        <Button x:Name="CloseBtn" Style="{DynamicResource CloseButton}" ToolTip="Close"/>
      </StackPanel>

      <Grid x:Name="SettingsPanel" Grid.RowSpan="5" Grid.ColumnSpan="5" Background="#C8080604" Visibility="Collapsed" Panel.ZIndex="10">
        <ContentControl Width="600" VerticalAlignment="Center" HorizontalAlignment="Center" Style="{DynamicResource Dialog}" Tag="SETTINGS">
          <StackPanel>
            <TextBlock Style="{DynamicResource Body}" Text="Where you play" Margin="0,0,0,6"/>
            <StackPanel Orientation="Horizontal">
              <RadioButton x:Name="FriendMode" GroupName="Mode" Style="{DynamicResource Pick}" Content="On a friend's server"/>
              <RadioButton x:Name="SoloMode" GroupName="Mode" Style="{DynamicResource Pick}" Content="On my own (a realm of my own on this PC)"/>
            </StackPanel>
            <TextBlock Style="{DynamicResource Body}" Text="Your World of Warcraft 1.12.1 folder (the one with WoW.exe and a Data folder)" Margin="0,14,0,5"/>
            <DockPanel>
              <Button x:Name="BrowseBtn" DockPanel.Dock="Right" Content="Browse..." Style="{DynamicResource GoldButton}" Margin="8,0,0,0"/>
              <TextBox x:Name="GameBox" Style="{DynamicResource Field}" Height="34"/>
            </DockPanel>
            <TextBlock x:Name="ServerLabel" Style="{DynamicResource Body}" Text="Your friend's server address (their Tailscale address, like 100.101.102.103)" Margin="0,12,0,5"/>
            <TextBox x:Name="ServerBox" Style="{DynamicResource Field}" Height="34"/>
            <TextBlock Style="{DynamicResource Body}" Text="Your name, for the logs and feedback you send" Margin="0,12,0,5"/>
            <TextBox x:Name="NameBox" Style="{DynamicResource Field}" Height="34"/>
            <CheckBox x:Name="LogsCheck" Style="{DynamicResource Check}" Margin="0,14,0,0">
              <TextBlock TextWrapping="Wrap" Text="Send my game logs and motion recordings to my friend (head and hands, and the moves that fired: for fixing bugs and tuning the moves; never voice or video)"/>
            </CheckBox>
            <CheckBox x:Name="AskCheck" Style="{DynamicResource Check}" Margin="0,8,0,0">
              <TextBlock TextWrapping="Wrap" Text="Ask me how it went after I play"/>
            </CheckBox>
            <TextBlock x:Name="SettingsError" Style="{DynamicResource Body}" Foreground="#F08A6A" Margin="0,8,0,0"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
              <Button x:Name="CancelBtn" Content="Cancel" Style="{DynamicResource GoldButton}" Width="130" Margin="0,0,10,0"/>
              <Button x:Name="SaveBtn" Content="Save" Style="{DynamicResource GoldButton}" Width="130"/>
            </StackPanel>
          </StackPanel>
        </ContentControl>
      </Grid>

      <Grid x:Name="ConfirmPanel" Grid.RowSpan="5" Grid.ColumnSpan="5" Background="#C8080604" Visibility="Collapsed" Panel.ZIndex="10">
        <ContentControl x:Name="ConfirmBox" Width="540" VerticalAlignment="Center" HorizontalAlignment="Center" Style="{DynamicResource Dialog}" Tag="GO BACK A VERSION">
          <StackPanel>
            <TextBlock x:Name="ConfirmText" Style="{DynamicResource Body}"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,18,0,0">
              <Button x:Name="ConfirmNo" Content="Cancel" Style="{DynamicResource GoldButton}" Width="130" Margin="0,0,10,0"/>
              <Button x:Name="ConfirmYes" Content="Go back" Style="{DynamicResource GoldButton}" Width="130"/>
            </StackPanel>
          </StackPanel>
        </ContentControl>
      </Grid>

      <Grid x:Name="FeedbackPanel" Grid.RowSpan="5" Grid.ColumnSpan="5" Background="#C8080604" Visibility="Collapsed" Panel.ZIndex="10">
        <ContentControl Width="640" VerticalAlignment="Center" HorizontalAlignment="Center" Style="{DynamicResource Dialog}" Tag="HOW WAS IT?">
          <StackPanel>
            <TextBlock Style="{DynamicResource Small}" Margin="0,0,0,8"
                       Text="Your answers, with what the session measured, go to the project to make Vanilla VR better. Every question is optional."/>
            <Grid>
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="190"/>
                <ColumnDefinition Width="72"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
              </Grid.ColumnDefinitions>
              <Grid.RowDefinitions>
                <RowDefinition Height="30"/>
                <RowDefinition Height="30"/>
                <RowDefinition Height="30"/>
              </Grid.RowDefinitions>
              <TextBlock Text="Fun" Style="{DynamicResource Body}" VerticalAlignment="Center"/>
              <TextBlock Grid.Column="1" Text="boring" Style="{DynamicResource Small}" VerticalAlignment="Center" HorizontalAlignment="Right" Margin="0,0,10,0"/>
              <StackPanel x:Name="FunRow" Grid.Column="2" Orientation="Horizontal"/>
              <TextBlock Grid.Column="3" Text="a blast" Style="{DynamicResource Small}" VerticalAlignment="Center"/>
              <TextBlock Grid.Row="1" Text="Did it work?" Style="{DynamicResource Body}" VerticalAlignment="Center"/>
              <TextBlock Grid.Row="1" Grid.Column="1" Text="broken" Style="{DynamicResource Small}" VerticalAlignment="Center" HorizontalAlignment="Right" Margin="0,0,10,0"/>
              <StackPanel x:Name="WorksRow" Grid.Row="1" Grid.Column="2" Orientation="Horizontal"/>
              <TextBlock Grid.Row="1" Grid.Column="3" Text="flawless" Style="{DynamicResource Small}" VerticalAlignment="Center"/>
              <TextBlock Grid.Row="2" Text="Your arms and back now" Style="{DynamicResource Body}" VerticalAlignment="Center"/>
              <TextBlock Grid.Row="2" Grid.Column="1" Text="worn out" Style="{DynamicResource Small}" VerticalAlignment="Center" HorizontalAlignment="Right" Margin="0,0,10,0"/>
              <StackPanel x:Name="BodyRow" Grid.Row="2" Grid.Column="2" Orientation="Horizontal"/>
              <TextBlock Grid.Row="2" Grid.Column="3" Text="fresh" Style="{DynamicResource Small}" VerticalAlignment="Center"/>
            </Grid>
            <TextBlock Style="{DynamicResource Body}" Text="What felt great?" Margin="0,10,0,4"/>
            <TextBox x:Name="GreatBox" Style="{DynamicResource Field}" Height="54" AcceptsReturn="True" TextWrapping="Wrap"
                     VerticalContentAlignment="Top" VerticalScrollBarVisibility="Auto"/>
            <TextBlock Style="{DynamicResource Body}" Text="What broke, misfired or tired you out?" Margin="0,8,0,4"/>
            <TextBox x:Name="BrokeBox" Style="{DynamicResource Field}" Height="54" AcceptsReturn="True" TextWrapping="Wrap"
                     VerticalContentAlignment="Top" VerticalScrollBarVisibility="Auto"/>
            <CheckBox x:Name="NamedCheck" Style="{DynamicResource Check}" Margin="0,8,0,0">
              <TextBlock TextWrapping="Wrap" Text="Put my name on it (otherwise it says a playtester)"/>
            </CheckBox>
            <TextBlock x:Name="SentWith" Style="{DynamicResource Small}" Margin="0,8,0,0"/>
            <TextBlock x:Name="FeedbackStatus" Style="{DynamicResource Body}" Margin="0,6,0,0"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,10,0,0">
              <Button x:Name="FeedbackNo" Content="Not now" Style="{DynamicResource GoldButton}" Width="120" Margin="0,0,10,0"/>
              <Button x:Name="FeedbackPost" Content="Post on GitHub" Style="{DynamicResource GoldButton}" Width="160" Margin="0,0,10,0"/>
              <Button x:Name="FeedbackSend" Content="Send" Style="{DynamicResource GoldButton}" Width="120"/>
            </StackPanel>
          </StackPanel>
        </ContentControl>
      </Grid>
    </Grid>
  </Border>
</Window>
'@

$window = [Windows.Markup.XamlReader]::Load((New-Object Xml.XmlNodeReader $xaml))
$ui = @{}
foreach ($n in 'Root', 'Backdrop', 'Shade', 'Brand', 'Crest', 'VrMark', 'MinBtn', 'CloseBtn', 'NewsList', 'RealmDot', 'RealmText',
    'ServerText', 'VersionText', 'VrDot', 'VrText', 'SettingsBtn', 'ControlsBtn', 'FeedbackBtn', 'LogsBtn', 'RollbackBtn',
    'StatusText', 'Progress', 'PlayBtn', 'SettingsPanel', 'FriendMode', 'SoloMode', 'GameBox', 'BrowseBtn', 'ServerLabel',
    'ServerBox', 'NameBox', 'LogsCheck', 'AskCheck', 'SettingsError', 'SaveBtn', 'CancelBtn', 'ConfirmPanel', 'ConfirmBox',
    'ConfirmText', 'ConfirmYes', 'ConfirmNo', 'FeedbackPanel', 'FunRow', 'WorksRow', 'BodyRow', 'GreatBox', 'BrokeBox',
    'NamedCheck', 'SentWith', 'FeedbackStatus', 'FeedbackNo', 'FeedbackPost', 'FeedbackSend') {
    $ui[$n] = $window.FindName($n)
}

# The three 1-to-5 rows of the feedback card.
$ratings = @{}
foreach ($row in 'Fun', 'Works', 'Body') {
    $ratings[$row] = @()
    foreach ($i in 1..5) {
        $rb = New-Object Windows.Controls.RadioButton
        $rb.GroupName = $row
        $rb.Content = "$i"
        $rb.SetResourceReference([Windows.FrameworkElement]::StyleProperty, 'Pick')
        [void]$ui["${row}Row"].Children.Add($rb)
        $ratings[$row] += $rb
    }
}
function Get-Rating([string]$row) {
    for ($i = 0; $i -lt 5; $i++) { if ($ratings[$row][$i].IsChecked) { return $i + 1 } }
    return $null
}

function Brush([string]$hex) {
    return New-Object Windows.Media.SolidColorBrush ([Windows.Media.ColorConverter]::ConvertFromString($hex))
}
$colors = @{ Grey = '#7A7060'; Amber = '#E0A83C'; Green = '#5BC46A'; Red = '#D0503C' }

function Set-Status([string]$text, [string]$color = '') {
    $ui.StatusText.Text = $text
    $ui.StatusText.Foreground = if ($color) { Brush $color } else { $window.FindResource('Parch') }
}

# ---------------------------------------------------------------- the game's look

# The art is there, of this version, and from the game folder set now.
function Test-Art($s) {
    $txt = Join-Path $artDir 'art.txt'
    if (-not (Test-Path $txt)) { return $false }
    $t = Get-Content $txt
    if (-not ($t -contains "VERSION=$artVersion")) { return $false }
    if ($s -and $s['GAME'] -and -not ($t -contains "DATA=$(Join-Path $s['GAME'] 'Data')")) { return $false }
    foreach ($f in 'screen-1.png', 'button-up.png', 'dialog-tl.png', 'FRIZQT__.TTF', 'MORPHEUS.TTF') {
        if (-not (Test-Path (Join-Path $artDir $f))) { return $false }
    }
    return $true
}

# Reads the art from your game (launcher-art.exe, a fraction of a second): $true when it is there.
function Update-Art($s) {
    if (Test-Art $s) { return $true }
    $exe = Join-Path $kitDir 'launcher-art.exe'
    if (-not (Test-Path $exe) -or -not (Test-GameDir $s['GAME'])) { return $false }
    try {
        $p = Start-Process -FilePath $exe -ArgumentList @("`"$(Join-Path $s['GAME'] 'Data')`"", "`"$artDir`"") `
            -WindowStyle Hidden -PassThru
        if (-not $p.WaitForExit(30000)) { try { $p.Kill() } catch { }; return $false }
    } catch { return $false }
    return Test-Art $s
}

function Get-ArtImage([string]$name) {
    $b = New-Object Windows.Media.Imaging.BitmapImage
    $b.BeginInit()
    $b.CacheOption = [Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $b.UriSource = New-Object Uri (Join-Path $artDir $name)
    $b.EndInit()
    $b.Freeze()
    return $b
}

function New-Tile([string]$name, [double]$size) {
    $brush = New-Object Windows.Media.ImageBrush (Get-ArtImage $name)
    $brush.TileMode = [Windows.Media.TileMode]::Tile
    $brush.Stretch = [Windows.Media.Stretch]::Fill
    $brush.ViewportUnits = [Windows.Media.BrushMappingMode]::Absolute
    $brush.Viewport = New-Object Windows.Rect 0, 0, $size, $size
    $brush.Freeze()
    return $brush
}

# The game's login screen, in its own pieces: the dialog frame (the server alert's) at three
# quarters of the game's size, the red glue buttons, the loading screen's bar, Friz Quadrata.
$wowStyles = @'
<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
                    xmlns:sys="clr-namespace:System;assembly=mscorlib">
  <SolidColorBrush x:Key="Gold" Color="#FFC700"/>
  <SolidColorBrush x:Key="Parch" Color="#FFFFFF"/>
  <SolidColorBrush x:Key="ParchDim" Color="#C9C2B0"/>
  <SolidColorBrush x:Key="WindowEdge" Color="#000000"/>
  <sys:Double x:Key="BarHeight">40</sys:Double>
  <DropShadowEffect x:Key="GlueShadow" Color="#000000" BlurRadius="3" ShadowDepth="1.2" Direction="315" Opacity="1"/>

  <Style x:Key="Heading" TargetType="TextBlock">
    <Setter Property="FontFamily" Value="{DynamicResource Serif}"/>
    <Setter Property="FontSize" Value="14"/>
    <Setter Property="Foreground" Value="{DynamicResource Gold}"/>
    <Setter Property="Effect" Value="{StaticResource GlueShadow}"/>
  </Style>
  <Style x:Key="Body" TargetType="TextBlock">
    <Setter Property="FontFamily" Value="{DynamicResource BodyFont}"/>
    <Setter Property="FontSize" Value="13"/>
    <Setter Property="Foreground" Value="{DynamicResource Parch}"/>
    <Setter Property="TextWrapping" Value="Wrap"/>
    <Setter Property="Effect" Value="{StaticResource GlueShadow}"/>
  </Style>
  <Style x:Key="Small" TargetType="TextBlock" BasedOn="{StaticResource Body}">
    <Setter Property="FontSize" Value="11.5"/>
    <Setter Property="Foreground" Value="{DynamicResource ParchDim}"/>
  </Style>

  <Style x:Key="Panel" TargetType="ContentControl">
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ContentControl">
          <Grid>
            <Border Margin="8,9,9,8" Background="{DynamicResource Tile.dialog-bg}"/>
            <Grid>
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="24"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="24"/>
              </Grid.ColumnDefinitions>
              <Grid.RowDefinitions>
                <RowDefinition Height="24"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="24"/>
              </Grid.RowDefinitions>
              <Image Source="{DynamicResource Art.dialog-tl}" Stretch="Fill"/>
              <Border Grid.Column="1" Background="{DynamicResource Tile.dialog-t}"/>
              <Image Grid.Column="2" Source="{DynamicResource Art.dialog-tr}" Stretch="Fill"/>
              <Border Grid.Row="1" Background="{DynamicResource Tile.dialog-l}"/>
              <Border Grid.Row="1" Grid.Column="2" Background="{DynamicResource Tile.dialog-r}"/>
              <Image Grid.Row="2" Source="{DynamicResource Art.dialog-bl}" Stretch="Fill"/>
              <Border Grid.Row="2" Grid.Column="1" Background="{DynamicResource Tile.dialog-b}"/>
              <Image Grid.Row="2" Grid.Column="2" Source="{DynamicResource Art.dialog-br}" Stretch="Fill"/>
            </Grid>
            <ContentPresenter/>
          </Grid>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="Dialog" TargetType="ContentControl">
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ContentControl">
          <Grid>
            <ContentControl Style="{DynamicResource Panel}" Margin="0,16,0,0">
              <ContentPresenter Margin="30,34,30,24"/>
            </ContentControl>
            <Grid VerticalAlignment="Top" HorizontalAlignment="Center" Width="340" Height="64" Margin="0,-4,0,0">
              <Image Source="{DynamicResource Art.header}" Stretch="Fill"/>
              <TextBlock Text="{Binding Tag, RelativeSource={RelativeSource TemplatedParent}}" HorizontalAlignment="Center"
                         VerticalAlignment="Top" Margin="0,14,0,0" FontFamily="{DynamicResource Serif}" FontSize="14"
                         Foreground="{DynamicResource Gold}" Effect="{StaticResource GlueShadow}"/>
            </Grid>
          </Grid>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style x:Key="GoldButton" TargetType="Button">
    <Setter Property="Foreground" Value="{DynamicResource Gold}"/>
    <Setter Property="FontFamily" Value="{DynamicResource Serif}"/>
    <Setter Property="FontSize" Value="13"/>
    <Setter Property="Height" Value="36"/>
    <Setter Property="MinWidth" Value="110"/>
    <Setter Property="Padding" Value="18,0,18,3"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Grid>
            <Border x:Name="Face" Background="{DynamicResource Fill.button-up}"/>
            <Border x:Name="Hi" Background="{DynamicResource Fill.button-highlight}" Visibility="Hidden"/>
            <ContentPresenter x:Name="Text" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="{TemplateBinding Padding}"
                              Effect="{StaticResource GlueShadow}"/>
          </Grid>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True">
              <Setter TargetName="Hi" Property="Visibility" Value="Visible"/>
              <Setter Property="Foreground" Value="#FFFFFF"/>
            </Trigger>
            <Trigger Property="IsPressed" Value="True">
              <Setter TargetName="Face" Property="Background" Value="{DynamicResource Fill.button-down}"/>
              <Setter TargetName="Text" Property="RenderTransform">
                <Setter.Value><TranslateTransform X="1" Y="1"/></Setter.Value>
              </Setter>
            </Trigger>
            <Trigger Property="IsEnabled" Value="False">
              <Setter TargetName="Face" Property="Background" Value="{DynamicResource Fill.button-disabled}"/>
              <Setter TargetName="Hi" Property="Visibility" Value="Hidden"/>
              <Setter Property="Foreground" Value="#808080"/>
            </Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="PlayButton" TargetType="Button" BasedOn="{StaticResource GoldButton}">
    <Setter Property="FontSize" Value="24"/>
    <Setter Property="Padding" Value="16,0,16,5"/>
  </Style>

  <Style x:Key="CloseButton" TargetType="Button">
    <Setter Property="Width" Value="32"/>
    <Setter Property="Height" Value="32"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Grid Background="Transparent">
            <Image x:Name="Up" Source="{DynamicResource Art.close-up}"/>
            <Image x:Name="Down" Source="{DynamicResource Art.close-down}" Visibility="Hidden"/>
            <Image x:Name="Hi" Source="{DynamicResource Art.close-highlight}" Visibility="Hidden"/>
          </Grid>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Hi" Property="Visibility" Value="Visible"/></Trigger>
            <Trigger Property="IsPressed" Value="True">
              <Setter TargetName="Down" Property="Visibility" Value="Visible"/>
              <Setter TargetName="Up" Property="Visibility" Value="Hidden"/>
            </Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="MinButton" TargetType="Button">
    <Setter Property="Width" Value="32"/>
    <Setter Property="Height" Value="32"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Button">
          <Grid Background="Transparent">
            <Grid Width="19" Height="19">
              <Image x:Name="Up" Source="{DynamicResource Art.min-up}"/>
              <Image x:Name="Down" Source="{DynamicResource Art.min-down}" Visibility="Hidden"/>
              <Image x:Name="Hi" Source="{DynamicResource Art.min-highlight}" Visibility="Hidden"/>
            </Grid>
          </Grid>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Hi" Property="Visibility" Value="Visible"/></Trigger>
            <Trigger Property="IsPressed" Value="True">
              <Setter TargetName="Down" Property="Visibility" Value="Visible"/>
              <Setter TargetName="Up" Property="Visibility" Value="Hidden"/>
            </Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style x:Key="Field" TargetType="TextBox">
    <Setter Property="Foreground" Value="#FFFFFF"/>
    <Setter Property="CaretBrush" Value="#FFFFFF"/>
    <Setter Property="SelectionBrush" Value="#FFC700"/>
    <Setter Property="FontFamily" Value="{DynamicResource FieldFont}"/>
    <Setter Property="FontStretch" Value="Condensed"/>
    <Setter Property="FontSize" Value="16"/>
    <Setter Property="Padding" Value="9,4"/>
    <Setter Property="VerticalContentAlignment" Value="Center"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="TextBox">
          <Grid>
            <Border Margin="4" Background="#C0000000"/>
            <Grid>
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="12"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="12"/>
              </Grid.ColumnDefinitions>
              <Grid.RowDefinitions>
                <RowDefinition Height="12"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="12"/>
              </Grid.RowDefinitions>
              <Image Source="{DynamicResource Art.field-tl}" Stretch="Fill"/>
              <Border Grid.Column="1" Background="{DynamicResource Tile.field-t}"/>
              <Image Grid.Column="2" Source="{DynamicResource Art.field-tr}" Stretch="Fill"/>
              <Border Grid.Row="1" Background="{DynamicResource Tile.field-l}"/>
              <Border Grid.Row="1" Grid.Column="2" Background="{DynamicResource Tile.field-r}"/>
              <Image Grid.Row="2" Source="{DynamicResource Art.field-bl}" Stretch="Fill"/>
              <Border Grid.Row="2" Grid.Column="1" Background="{DynamicResource Tile.field-b}"/>
              <Image Grid.Row="2" Grid.Column="2" Source="{DynamicResource Art.field-br}" Stretch="Fill"/>
            </Grid>
            <ScrollViewer x:Name="PART_ContentHost" Margin="{TemplateBinding Padding}" VerticalAlignment="{TemplateBinding VerticalContentAlignment}"/>
          </Grid>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style x:Key="Check" TargetType="CheckBox">
    <Setter Property="Foreground" Value="#FFFFFF"/>
    <Setter Property="FontFamily" Value="{DynamicResource BodyFont}"/>
    <Setter Property="FontSize" Value="12.5"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="CheckBox">
          <DockPanel Background="Transparent">
            <Grid DockPanel.Dock="Left" Width="26" Height="26" VerticalAlignment="Top" Margin="-4,-4,2,0">
              <Image x:Name="Box" Source="{DynamicResource Art.check-up}"/>
              <Image x:Name="Hi" Source="{DynamicResource Art.check-highlight}" Visibility="Hidden"/>
              <Image x:Name="Mark" Source="{DynamicResource Art.check-check}" Visibility="Hidden"/>
            </Grid>
            <ContentPresenter VerticalAlignment="Center" Effect="{StaticResource GlueShadow}"/>
          </DockPanel>
          <ControlTemplate.Triggers>
            <Trigger Property="IsChecked" Value="True"><Setter TargetName="Mark" Property="Visibility" Value="Visible"/></Trigger>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Hi" Property="Visibility" Value="Visible"/></Trigger>
            <Trigger Property="IsPressed" Value="True"><Setter TargetName="Box" Property="Source" Value="{DynamicResource Art.check-down}"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="Pick" TargetType="RadioButton">
    <Setter Property="Foreground" Value="#FFFFFF"/>
    <Setter Property="FontFamily" Value="{DynamicResource BodyFont}"/>
    <Setter Property="FontSize" Value="12.5"/>
    <Setter Property="VerticalAlignment" Value="Center"/>
    <Setter Property="Margin" Value="0,0,10,0"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="RadioButton">
          <StackPanel Orientation="Horizontal" Background="Transparent">
            <Grid Width="26" Height="26">
              <Image x:Name="Box" Source="{DynamicResource Art.check-up}"/>
              <Image x:Name="Hi" Source="{DynamicResource Art.check-highlight}" Visibility="Hidden"/>
              <Image x:Name="Mark" Source="{DynamicResource Art.check-check}" Visibility="Hidden"/>
            </Grid>
            <ContentPresenter VerticalAlignment="Center" Margin="1,0,0,0" Effect="{StaticResource GlueShadow}"/>
          </StackPanel>
          <ControlTemplate.Triggers>
            <Trigger Property="IsChecked" Value="True"><Setter TargetName="Mark" Property="Visibility" Value="Visible"/></Trigger>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Hi" Property="Visibility" Value="Visible"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>

  <Style x:Key="GoldBar" TargetType="ProgressBar">
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ProgressBar">
          <Grid>
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="0.0625*"/>
              <ColumnDefinition Width="0.875*"/>
              <ColumnDefinition Width="0.0625*"/>
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
              <RowDefinition Height="0.25*"/>
              <RowDefinition Height="0.5*"/>
              <RowDefinition Height="0.25*"/>
            </Grid.RowDefinitions>
            <Border Grid.Row="1" Grid.Column="1" Background="#E0000000"/>
            <Grid x:Name="PART_Track" Grid.Row="1" Grid.Column="1">
              <Image x:Name="PART_Indicator" Source="{DynamicResource Art.bar-fill}" Stretch="Fill" HorizontalAlignment="Left"/>
            </Grid>
            <Image Grid.RowSpan="3" Grid.ColumnSpan="3" Source="{DynamicResource Art.bar-border}" Stretch="Fill"/>
          </Grid>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
</ResourceDictionary>
'@

$script:worn = 'plain'
# Dresses the window in the game's art; $false (the window's own look kept) when it is not there.
function Set-WowLook {
    try {
        $res = $window.Resources
        # Into the window's resources as the objects themselves, never PowerShell's wrappers.
        $put = { param($key, $value) $res[$key] = $value.psobject.BaseObject }
        foreach ($n in 'dialog-tl', 'dialog-tr', 'dialog-bl', 'dialog-br', 'header', 'button-up', 'button-down', 'button-disabled',
            'button-highlight', 'close-up', 'close-down', 'close-highlight', 'min-up', 'min-down', 'min-highlight', 'check-up',
            'check-down', 'check-highlight', 'check-check', 'bar-border', 'bar-fill', 'field-tl', 'field-tr', 'field-bl', 'field-br') {
            & $put "Art.$n" (Get-ArtImage "$n.png")
        }
        foreach ($n in 'dialog-t', 'dialog-b', 'dialog-l', 'dialog-r') { & $put "Tile.$n" (New-Tile "$n.png" 24) }
        foreach ($n in 'field-t', 'field-b', 'field-l', 'field-r') { & $put "Tile.$n" (New-Tile "$n.png" 12) }
        & $put 'Tile.dialog-bg' (New-Tile 'dialog-bg.png' 24)
        # The glue buttons' faces, stretched over each button as the game stretches them.
        foreach ($n in 'button-up', 'button-down', 'button-disabled', 'button-highlight') {
            $fill = New-Object Windows.Media.ImageBrush (Get-ArtImage "$n.png")
            $fill.Stretch = [Windows.Media.Stretch]::Fill
            $fill.Freeze()
            & $put "Fill.$n" $fill
        }
        $base = [Uri]::new(((Join-Path $artDir 'x') -replace 'x$', ''))
        & $put 'Serif' ([Windows.Media.FontFamily]::new($base, './#Friz Quadrata TT'))
        & $put 'BodyFont' ([Windows.Media.FontFamily]::new($base, './#Friz Quadrata TT'))
        & $put 'FieldFont' ([Windows.Media.FontFamily]::new($base, './#Arial'))
        & $put 'MarkFont' ([Windows.Media.FontFamily]::new($base, './#Morpheus'))
        $wow = [Windows.Markup.XamlReader]::Parse($wowStyles)
        foreach ($k in @($wow.Keys)) { & $put $k $wow[$k] }
        # One of the two continents' loading screens, as the game picks one.
        $screen = if ($Snapshot) { 'screen-1.png' } else { "screen-$(Get-Random -Minimum 1 -Maximum 3).png" }
        $ui.Backdrop.Source = Get-ArtImage $screen
        $ui.Backdrop.Visibility = 'Visible'
        $ui.Shade.Visibility = 'Visible'
        $ui.Brand.Visibility = 'Collapsed'
        $ui.VrMark.Visibility = 'Visible'
        $ui.Root.Background = Brush '#000000'
        $script:worn = 'wow'
        Show-News $script:news
        return $true
    } catch {
        $script:lookError = "$($_.Exception.Message) (line $($_.InvocationInfo.ScriptLineNumber))"
        return $false
    }
}

# ---------------------------------------------------------------- the window's parts

function Set-Realm([string]$state, [string]$detail) {
    $map = @{
        unset     = @($colors.Grey, 'Not set: press Settings')
        checking  = @($colors.Amber, 'Looking...')
        online    = @($colors.Green, 'Online')
        offline   = @($colors.Red, 'Can''t reach it')
        unbuilt   = @($colors.Amber, 'Yours, not built yet')
        building  = @($colors.Amber, 'Yours, being built')
        asleep    = @($colors.Green, 'Yours, ready')
        waking    = @($colors.Amber, 'Yours, waking up')
        awake     = @($colors.Green, 'Yours, awake')
        sleeping  = @($colors.Amber, 'Yours, going to sleep')
        failed    = @($colors.Red, 'Yours, stopped')
    }
    $ui.RealmDot.Fill = Brush $map[$state][0]
    $ui.RealmText.Text = $map[$state][1]
    $ui.ServerText.Text = $detail
}

$script:news = @()
function Show-News($items) {
    $script:news = $items
    $ui.NewsList.Children.Clear()
    $items = @($items | Where-Object { $_ })
    if ($items.Count -eq 0) {
        $items = @([pscustomobject]@{
                version = 'Welcome to Vanilla VR'
                notes   = 'Patch notes show here once the launcher has checked for updates. Set your game folder in ' +
                'Settings, and either your friend''s server or a realm of your own; start SteamVR, then press Play.'
            })
    }
    foreach ($h in $items) {
        $title = New-Object Windows.Controls.TextBlock
        $title.Text = "$($h.version)"
        $title.Style = $window.FindResource('Heading')
        $title.FontSize = 15
        $body = New-Object Windows.Controls.TextBlock
        $body.Text = "$($h.notes)"
        $body.Style = $window.FindResource('Body')
        $body.Margin = New-Object Windows.Thickness 0, 3, 0, 14
        [void]$ui.NewsList.Children.Add($title)
        [void]$ui.NewsList.Children.Add($body)
    }
}

function Show-Version {
    $v = Get-Version
    $ui.VersionText.Text = if ($v) { $v } else { 'as downloaded' }
    $ui.RollbackBtn.IsEnabled = (Test-Path (Join-Path $kitDir 'previous')) -and -not $script:job
}

function Show-Headset {
    $vr = Get-Process -Name 'vrserver', 'vrmonitor' -ErrorAction SilentlyContinue
    if ($vr) {
        $ui.VrDot.Fill = Brush $colors.Green
        $ui.VrText.Text = 'SteamVR is running'
    } else {
        $ui.VrDot.Fill = Brush $colors.Amber
        $ui.VrText.Text = 'SteamVR is not running: start it before Play'
    }
}

function Test-Solo($s) { return $s['MODE'] -eq 'solo' }
function Test-Ready($s) { return (Test-GameDir $s['GAME']) -and ((Test-Solo $s) -or [bool]$s['SERVER']) }

function Set-ModeLabels {
    if ($ui.SoloMode.IsChecked) {
        $ui.ServerLabel.Text = 'Your friend''s address, if you have one (optional: your updates and feedback go through them)'
    } else {
        $ui.ServerLabel.Text = 'Your friend''s server address (their Tailscale address, like 100.101.102.103)'
    }
}

function Show-Settings {
    $s = Read-Settings
    $ui.GameBox.Text = "$($s['GAME'])"
    $suggest = ''
    $given = Join-Path $kitDir 'server.txt'
    if (Test-Path $given) { $suggest = "$(Get-Content $given -TotalCount 1)".Trim() }
    $ui.ServerBox.Text = if ($s['SERVER']) { $s['SERVER'] } else { $suggest }
    $ui.NameBox.Text = Get-PlayerName $s
    $ui.SoloMode.IsChecked = Test-Solo $s
    $ui.FriendMode.IsChecked = -not (Test-Solo $s)
    Set-ModeLabels
    $ui.LogsCheck.IsChecked = $s['SEND_LOGS'] -ne 'no'
    $ui.AskCheck.IsChecked = $s['FEEDBACK'] -ne 'no'
    $ui.SettingsError.Text = ''
    $ui.CancelBtn.IsEnabled = Test-Ready $s
    $ui.SettingsPanel.Visibility = 'Visible'
}

# A question with two answers; $yes runs on the second.
$script:confirmYes = $null
function Show-Confirm([string]$title, [string]$text, [string]$yesLabel, [string]$noLabel, [scriptblock]$yes) {
    $ui.ConfirmBox.Tag = $title
    $ui.ConfirmText.Text = $text
    $ui.ConfirmYes.Content = $yesLabel
    $ui.ConfirmNo.Content = $noLabel
    $script:confirmYes = $yes
    $ui.ConfirmPanel.Visibility = 'Visible'
}

# ---------------------------------------------------------------- work away from the window

# One piece of work at a time in its own runspace, the rest queued: its progress in $sync for the
# window's clock, then its $then with the result.
$sync = [hashtable]::Synchronized(@{})
$script:job = $null
$script:queue = New-Object Collections.ArrayList
$work = {
    param($kitDir, $task, $p)
    $ErrorActionPreference = 'Stop'
    try {
        . (Join-Path $kitDir 'play.ps1') -Library
        $global:VanillaReport = {
            param($text, $fraction)
            $sync.message = $text
            $sync.reports = 1 + $sync.reports
            if ($fraction -ge 0) { $sync.fraction = [double]$fraction }
        }
        $s = $p.Settings
        switch ($task) {
            'check' {
                # Your friend's server, then the update (theirs, or with none GitHub's when you play
                # solo), then what you have to send them.
                $server = $s['SERVER']
                $solo = $s['MODE'] -eq 'solo'
                $sync.realm = [bool]($server -and (Test-Tcp $server 3724))
                $hostUp = $sync.realm -or ($solo -and $server -and (Test-Tcp $server $updatesPort))
                $sync.hostUp = $hostUp
                if ($hostUp) {
                    $sync.message = 'Checking for updates...'
                    $sync.result = Update-Kit $server $s
                    try { Send-Logs $server (Get-PlayerName $s) ($s['SEND_LOGS'] -ne 'no') } catch { }
                } elseif ($solo) {
                    $sync.message = 'Checking GitHub for updates...'
                    $sync.result = Update-Kit '' $s -GitHub
                } else {
                    $sync.message = "Can't reach the server at ${server}."
                }
            }
            'build' { Install-Solo $s }
            'wake' { Start-Solo }
            'sleep' { Stop-Solo }
            'report' { $sync.result = New-SessionReport $p.Session }
            'send' {
                $server = $s['SERVER']
                if ($server -and ((Test-Tcp $server $updatesPort))) {
                    Send-Logs $server (Get-PlayerName $s) ($s['SEND_LOGS'] -ne 'no')
                    $sync.result = 'sent'
                } else {
                    $sync.result = 'kept'
                }
            }
        }
    } catch {
        $sync.error = $_.Exception.Message
    } finally {
        $sync.done = $true
    }
}

function Add-Work([string]$task, [scriptblock]$then, $session = $null) {
    [void]$script:queue.Add(@{ Task = $task; Then = $then; Session = $session })
}

function Start-NextWork {
    if ($script:job -or $script:queue.Count -eq 0) { return }
    $next = $script:queue[0]
    $script:queue.RemoveAt(0)
    $sync.Clear()
    $sync.message = ''
    $sync.fraction = -1.0
    $sync.reports = 0
    $sync.done = $false
    $ps = [PowerShell]::Create()
    $ps.Runspace = [RunspaceFactory]::CreateRunspace()
    $ps.Runspace.Open()
    $ps.Runspace.SessionStateProxy.SetVariable('sync', $sync)
    [void]$ps.AddScript($work).AddArgument($kitDir).AddArgument($next.Task).AddArgument(@{ Settings = (Read-Settings); Session = $next.Session })
    $script:job = @{ Task = $next.Task; Then = $next.Then; ps = $ps; handle = $ps.BeginInvoke() }
    $ui.RollbackBtn.IsEnabled = $false
}

function Complete-Work {
    $j = $script:job
    try { [void]$j.ps.EndInvoke($j.handle) } catch { }
    $j.ps.Runspace.Dispose()
    $j.ps.Dispose()
    $script:job = $null
    $result = @{ Error = $sync.error; Result = $sync.result; Realm = $sync.realm; HostUp = $sync.hostUp; Message = $sync.message }
    Show-Version
    if ($j.Then) { & $j.Then $result }
}

# ---------------------------------------------------------------- the check, your realm, a session

function Start-Check {
    $s = Read-Settings
    if (-not (Test-Ready $s)) {
        Set-Realm 'unset' ''
        $ui.PlayBtn.IsEnabled = $false
        Show-Settings
        return
    }
    if (Test-Solo $s) { Set-Realm 'checking' 'on this PC' } else { Set-Realm 'checking' $s['SERVER'] }
    Set-Status 'Checking for updates...'
    $ui.Progress.Value = 0
    $ui.PlayBtn.IsEnabled = $false
    Add-Work 'check' { param($r) Complete-Check $r }
}

function Complete-Check($r) {
    $s = Read-Settings
    $solo = Test-Solo $s
    $u = $r.Result
    if ($u -and @($u.History).Count -gt 0) { Show-News $u.History }
    # A new launcher or engine: the window starts again on it.
    if ($u -and $u.Status -eq 'updated' -and (@($u.Changed) | Where-Object { $_ -in 'launcher.ps1', 'play.ps1', 'solo.ps1' })) {
        Set-Status "Updated to $($u.Version). Opening the new launcher..." $colors.Green
        Restart-Launcher
        return
    }
    if (-not (Test-Art $s) -and (Update-Art $s)) { [void](Set-WowLook) }
    if ($solo) { Show-SoloRealm } elseif ($r.Realm) { Set-Realm 'online' $s['SERVER'] } else { Set-Realm 'offline' $s['SERVER'] }
    if ($r.Error) {
        Set-Status "The update failed: $($r.Error) You can still play the version you have." $colors.Amber
        $ui.Progress.Value = 0
    } elseif (-not $solo -and -not $r.Realm) {
        Set-Status 'Can''t reach your friend''s server: is Tailscale connected, and is their server running? You can still start the game.' $colors.Amber
    } else {
        switch ("$($u.Status)") {
            'updated' { Set-Status "Updated to $($u.Version). Ready to play." $colors.Green; $ui.Progress.Value = 1 }
            'current' { Set-Status 'Up to date. Ready to play.' $colors.Green; $ui.Progress.Value = 1 }
            default { Set-Status "$($r.Message) Ready to play." }
        }
        if ($solo -and -not (Test-SoloBuilt)) { Set-Status 'Press Play to build your own realm (once, about an hour).' $colors.Amber }
    }
    $ui.PlayBtn.IsEnabled = $true
    # Your realm wakes while you read the news, so Play is quick.
    if ($solo -and (Test-SoloBuilt) -and -not (Test-SoloAwake)) { Start-Wake $false }
    if ($AutoPlay -and -not $script:autoPlayed) {
        $script:autoPlayed = $true
        $ui.PlayBtn.RaiseEvent((New-Object Windows.RoutedEventArgs ([Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
    }
}

function Show-SoloRealm {
    if (Test-SoloAwake) { Set-Realm 'awake' 'on this PC' }
    elseif (Test-SoloBuilt) { Set-Realm 'asleep' 'on this PC' }
    else { Set-Realm 'unbuilt' 'on this PC' }
}

function Restart-Launcher {
    Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-WindowStyle', 'Hidden',
        '-File', "`"$(Join-Path $kitDir 'launcher.ps1')`""
    $script:closing = $true
    $window.Close()
}

$script:playWhenAwake = $false
function Start-Wake([bool]$play) {
    if ($play) { $script:playWhenAwake = $true }
    if ($script:job -and $script:job.Task -eq 'wake') { return }
    if (@($script:queue | Where-Object { $_.Task -eq 'wake' }).Count -gt 0) { return }
    Set-Realm 'waking' 'on this PC'
    Add-Work 'wake' {
        param($r)
        if ($r.Error) {
            Set-Realm 'failed' 'on this PC'
            Set-Status "Your realm did not wake: $($r.Error)" $colors.Red
            $script:playWhenAwake = $false
            return
        }
        Set-Realm 'awake' 'on this PC'
        Set-Status 'Your realm is awake. Ready to play.' $colors.Green
        $ui.Progress.Value = 1
        if ($script:playWhenAwake) { $script:playWhenAwake = $false; Start-Session (Read-Settings) }
    }
}

function Start-Build {
    Set-Realm 'building' 'on this PC'
    $ui.PlayBtn.IsEnabled = $false
    Add-Work 'build' {
        param($r)
        $ui.PlayBtn.IsEnabled = $true
        if ($r.Error) {
            Show-SoloRealm
            Set-Status "The build stopped: $($r.Error) Press Play to carry on from there." $colors.Red
            return
        }
        Set-Realm 'asleep' 'on this PC'
        Set-Status 'Your realm is built. Waking it...' $colors.Green
        Start-Wake $false
    }
}

# The game is on its way: the window steps aside until it closes.
$script:session = $null
function Start-Session($s) {
    if (Get-Process -Name 'benilla-vr' -ErrorAction SilentlyContinue) {
        Set-Status 'Vanilla VR is already running.' $colors.Amber
        return
    }
    try {
        $p = Start-Game $s
        $script:session = @{
            Process = $p; Stamp = $p.Stamp; Started = (Get-Date); Mode = $(if (Test-Solo $s) { 'solo' } else { 'friend' })
            SteamVR = [bool](Get-Process -Name 'vrserver' -ErrorAction SilentlyContinue)
        }
        $ui.PlayBtn.IsEnabled = $false
        if (Test-Solo $s) { Set-Status 'Vanilla VR is starting. It logs you in to your realm.' $colors.Green }
        else { Set-Status 'Vanilla VR is starting. Log in with the account and password your friend gave you.' $colors.Green }
        $script:hideAt = (Get-Date).AddSeconds(4)
    } catch {
        Set-Status "The game did not start: $($_.Exception.Message)" $colors.Red
    }
}

# The game has closed: your realm to sleep, the session's report made, and, after a real
# session, the question how it went. Otherwise the window goes once the work is done.
function Complete-Session {
    $sess = $script:session
    $script:session = $null
    $sess.Ended = Get-Date
    try { $sess.ExitCode = $sess.Process.ExitCode } catch { $sess.ExitCode = $null }
    $s = Read-Settings
    $minutes = ($sess.Ended - $sess.Started).TotalMinutes
    $ask = ($s['FEEDBACK'] -ne 'no') -and ($minutes -ge 5 -or $sess.ExitCode)
    $script:report = $null
    $script:afterSession = $true
    $script:lastSession = $sess
    if ($sess.Mode -eq 'solo') {
        Set-Realm 'sleeping' 'on this PC'
        Add-Work 'sleep' { param($r) Show-SoloRealm; Set-Status 'Your realm is asleep, your progress saved.' $colors.Green }
    }
    Add-Work 'report' {
        param($r)
        $script:report = $r.Result
        if ($script:report) { $ui.SentWith.Text = Get-SentWith $script:report }
        if ($script:pendingSend) { $p = $script:pendingSend; $script:pendingSend = $null; Send-Feedback $p }
    } $sess
    Add-Work 'send' { param($r) }
    $ui.PlayBtn.IsEnabled = $true
    if ($ask) {
        Show-Feedback
        $window.Show()
        [void]$window.Activate()
    } else {
        $script:closeWhenIdle = $true
        if ($sess.Mode -eq 'solo') { $window.Show() }
    }
}

# ---------------------------------------------------------------- feedback

$script:report = $null
$script:pendingSend = $null
$script:afterSession = $false
# What goes with the answers, in a line or two.
function Get-SentWith($report) {
    if (-not $report) {
        return 'Sent with it: how long you played and as whom, your PC and headset, your VR settings, what the session ' +
        'asked of your arms, the frame times, the moves that fired and the moments you marked (both sticks clicked).'
    }
    $parts = @()
    if ($report.play.character) { $parts += $report.play.character }
    if ($report.session.minutes) { $parts += "$($report.session.minutes) min" }
    $moves = 0
    foreach ($k in @($report.moves.Keys)) { $moves += [int]$report.moves[$k] }
    if ($moves) { $parts += "$moves moves" }
    $marks = @($report.game.marked_minutes).Count
    if ($marks) { $parts += "$marks marked moment(s)" }
    if ($null -ne $report.play.frame_p95_ms) { $parts += "frames p95 $($report.play.frame_p95_ms) ms" }
    if ($report.vr.system) { $parts += $report.vr.system }
    if ($report.pc.cpu) { $parts += 'your PC''s parts' }
    return 'Sent with it: ' + ($parts -join ', ') + ', your VR settings and the game''s error count.'
}

function Show-Feedback {
    foreach ($row in $ratings.Keys) { foreach ($rb in $ratings[$row]) { $rb.IsChecked = $false } }
    $ui.GreatBox.Text = ''
    $ui.BrokeBox.Text = ''
    $ui.NamedCheck.IsChecked = $false
    $ui.FeedbackStatus.Text = ''
    $ui.FeedbackSend.IsEnabled = $true
    $ui.FeedbackPost.IsEnabled = $true
    $ui.SentWith.Text = Get-SentWith $script:report
    $ui.FeedbackPanel.Visibility = 'Visible'
}

function Get-Answers([bool]$posted) {
    return @{
        fun = Get-Rating 'Fun'; works = Get-Rating 'Works'; body = Get-Rating 'Body'
        great = $ui.GreatBox.Text; broke = $ui.BrokeBox.Text; named = [bool]$ui.NamedCheck.IsChecked; posted = $posted
    }
}

function Test-Answered($a) {
    return [bool]($a.fun -or $a.works -or $a.body -or "$($a.great)".Trim() -or "$($a.broke)".Trim())
}

# Kept in feedback\, then to your friend's PC, which posts it to the project's GitHub.
function Send-Feedback($answers) {
    if (-not $script:report) {
        # The session's report is still being made: it goes when that is done.
        $script:pendingSend = $answers
        if (-not $script:job -and $script:queue.Count -eq 0) { Add-Work 'report' { param($r) $script:report = $r.Result; if ($script:pendingSend) { $p = $script:pendingSend; $script:pendingSend = $null; Send-Feedback $p } } }
        $ui.FeedbackStatus.Text = 'Gathering the session''s numbers...'
        return
    }
    $fb = Save-Feedback $script:report $answers
    if ($answers.posted) { Start-Process (Get-FeedbackUrl $fb) }
    $ui.FeedbackStatus.Text = 'Sending...'
    Add-Work 'send' {
        param($r)
        $s = Read-Settings
        if ($r.Result -eq 'sent') { $ui.FeedbackStatus.Text = 'Sent. Thank you!' }
        elseif ($s['SERVER']) { $ui.FeedbackStatus.Text = 'Saved: it goes to your friend the next time the launcher reaches them. Thank you!' }
        else { $ui.FeedbackStatus.Text = 'Saved here (feedback folder). Post on GitHub sends it to the project. Thank you!' }
        $script:feedbackCloseAt = (Get-Date).AddSeconds(2.5)
    }
}

# ---------------------------------------------------------------- the window's clock and buttons

$script:headsetAt = [DateTime]::MinValue
$script:hideAt = $null
$script:feedbackCloseAt = $null
$script:closeWhenIdle = $false
$script:closing = $false
$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(100)
$timer.Add_Tick({
        if ($script:job) {
            if ($sync.message) { Set-Status $sync.message }
            if ($sync.fraction -ge 0) { $ui.Progress.Value = [double]$sync.fraction }
            if ($sync.done) { Complete-Work }
        } else {
            Start-NextWork
        }
        if ($script:hideAt -and (Get-Date) -ge $script:hideAt) {
            $script:hideAt = $null
            if ($script:session) { $window.Hide() }
        }
        if ($script:session -and $script:session.Process.HasExited) { Complete-Session }
        if ($script:feedbackCloseAt -and (Get-Date) -ge $script:feedbackCloseAt) {
            $script:feedbackCloseAt = $null
            $ui.FeedbackPanel.Visibility = 'Collapsed'
            # After a session the launcher's work is done; opened by hand, it stays.
            if ($script:afterSession) { $script:closeWhenIdle = $true }
        }
        if ($script:closeWhenIdle -and -not $script:job -and $script:queue.Count -eq 0 -and -not $script:session -and
            $ui.FeedbackPanel.Visibility -ne 'Visible' -and $ui.SettingsPanel.Visibility -ne 'Visible') {
            $script:closeWhenIdle = $false
            $window.Close()
        }
        if ($window.IsVisible -and ([DateTime]::UtcNow - $script:headsetAt).TotalSeconds -ge 2) {
            $script:headsetAt = [DateTime]::UtcNow
            Show-Headset
        }
    })

# The window moves by any of its plain parts.
$window.Add_MouseLeftButtonDown({
        param($sender, $e)
        $src = $e.OriginalSource
        if ($src -is [Windows.Controls.Image] -or $src -is [Windows.Shapes.Rectangle] -or $src -is [Windows.Controls.Grid] -or
            $src -is [Windows.Controls.Border] -or $src -is [Windows.Controls.StackPanel]) {
            try { $window.DragMove() } catch { }
        }
    })
$ui.MinBtn.Add_Click({ $window.WindowState = 'Minimized' })
$ui.CloseBtn.Add_Click({ $window.Close() })
$ui.ControlsBtn.Add_Click({ Start-Process $controlsUrl })
$ui.LogsBtn.Add_Click({
        $logs = Join-Path $kitDir 'logs'
        New-Item -ItemType Directory -Force -Path $logs | Out-Null
        Start-Process 'explorer.exe' $logs
    })
$ui.FeedbackBtn.Add_Click({ Show-Feedback })
$ui.SettingsBtn.Add_Click({ Show-Settings })
$ui.FriendMode.Add_Checked({ Set-ModeLabels })
$ui.SoloMode.Add_Checked({ Set-ModeLabels })
$ui.CancelBtn.Add_Click({ $ui.SettingsPanel.Visibility = 'Collapsed' })
$ui.BrowseBtn.Add_Click({
        $d = New-Object System.Windows.Forms.FolderBrowserDialog
        $d.Description = 'Your World of Warcraft 1.12.1 folder (the one with WoW.exe and a Data folder)'
        if ($ui.GameBox.Text -and (Test-Path $ui.GameBox.Text)) { $d.SelectedPath = $ui.GameBox.Text }
        if ($d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $ui.GameBox.Text = $d.SelectedPath }
    })
$ui.SaveBtn.Add_Click({
        $game = $ui.GameBox.Text.Trim().Trim('"')
        $server = $ui.ServerBox.Text.Trim()
        $solo = [bool]$ui.SoloMode.IsChecked
        if (-not (Test-GameDir $game)) {
            $ui.SettingsError.Text = 'No 1.12.1 game in that folder: it needs Data\dbc.MPQ and Data\patch.MPQ.'
            return
        }
        if (-not $server -and -not $solo) {
            $ui.SettingsError.Text = 'Your friend''s server address is needed: ask them for it (their Tailscale address), or play on your own.'
            return
        }
        $s = Read-Settings
        $wasSolo = Test-Solo $s
        $s['GAME'] = $game
        if ($server) { $s['SERVER'] = $server } else { $s.Remove('SERVER') }
        if ($solo) { $s['MODE'] = 'solo' } else { $s.Remove('MODE') }
        $name = $ui.NameBox.Text.Trim() -replace '[^A-Za-z0-9._-]', ''
        $s['NAME'] = if ($name) { $name } else { 'friend' }
        if ($ui.LogsCheck.IsChecked) { $s.Remove('SEND_LOGS') } else { $s['SEND_LOGS'] = 'no' }
        if ($ui.AskCheck.IsChecked) { $s.Remove('FEEDBACK') } else { $s['FEEDBACK'] = 'no' }
        Save-Settings $s
        $ui.SettingsPanel.Visibility = 'Collapsed'
        # Away from playing solo: your realm goes to sleep.
        if ($wasSolo -and -not $solo -and (Test-SoloAwake)) { Add-Work 'sleep' { param($r) } }
        if ($script:worn -eq 'plain' -and (Update-Art $s)) { [void](Set-WowLook) }
        Start-Check
    })
$ui.RollbackBtn.Add_Click({
        $kept = Join-Path $kitDir 'previous\version.txt'
        $back = if (Test-Path $kept) { "$(Get-Content $kept -TotalCount 1)".Trim() } else { '' }
        if (-not $back) { $back = 'the version you had before' }
        $now = Get-Version
        Show-Confirm 'GO BACK A VERSION' "Go back to $back? The version you have now ($now) won't be installed again; the next one will." 'Go back' 'Cancel' {
            try {
                Undo-Update (Read-Settings)
                Show-Version
                Set-Status "Back to $(Get-Version). Ready to play." $colors.Green
            } catch {
                Set-Status $_.Exception.Message $colors.Red
            }
        }
    })
$ui.ConfirmNo.Add_Click({ $ui.ConfirmPanel.Visibility = 'Collapsed' })
$ui.ConfirmYes.Add_Click({
        $ui.ConfirmPanel.Visibility = 'Collapsed'
        if ($script:confirmYes) { & $script:confirmYes }
    })
$ui.PlayBtn.Add_Click({
        $s = Read-Settings
        if (-not (Test-Ready $s)) { Show-Settings; return }
        if (Get-Process -Name 'benilla-vr' -ErrorAction SilentlyContinue) {
            Set-Status 'Vanilla VR is already running.' $colors.Amber
            return
        }
        if (-not (Test-Solo $s)) { Start-Session $s; return }
        if ($script:job -and $script:job.Task -eq 'build') { return }
        # Your realm is saving and going to sleep: it can wake again once it has.
        if (($script:job -and $script:job.Task -eq 'sleep') -or @($script:queue | Where-Object { $_.Task -eq 'sleep' }).Count -gt 0) {
            Set-Status 'Your realm is saving your progress: press Play again in a moment.' $colors.Amber
            return
        }
        if (-not (Test-SoloBuilt)) {
            Show-Confirm 'BUILD YOUR REALM' ('Your own realm is built once, on this PC: about 130 MB of downloads (the free vMaNGOS ' +
                'server, its world database and the MariaDB database server), then your game''s maps, read from your 1.12.1 ' +
                'folder, which is never changed. That takes about an hour of your PC''s time and 3.5 GB of space. You can close ' +
                'the launcher meanwhile: the build carries on from where it stopped.') 'Build it' 'Not now' { Start-Build }
            return
        }
        if (Test-SoloAwake) { Start-Session $s; return }
        Set-Status 'Your realm is waking: the game starts as soon as it is up.' $colors.Amber
        Start-Wake $true
    })
$ui.FeedbackNo.Add_Click({
        $ui.FeedbackPanel.Visibility = 'Collapsed'
        if ($script:afterSession) { $script:closeWhenIdle = $true }
    })
$ui.FeedbackSend.Add_Click({
        $a = Get-Answers $false
        if (-not (Test-Answered $a)) { $ui.FeedbackStatus.Text = 'Pick a number or write a line first.'; return }
        $ui.FeedbackSend.IsEnabled = $false
        $ui.FeedbackPost.IsEnabled = $false
        Send-Feedback $a
    })
$ui.FeedbackPost.Add_Click({
        $a = Get-Answers $true
        if (-not (Test-Answered $a)) { $ui.FeedbackStatus.Text = 'Pick a number or write a line first.'; return }
        $ui.FeedbackSend.IsEnabled = $false
        $ui.FeedbackPost.IsEnabled = $false
        Send-Feedback $a
    })
# The window's own lines (going back a version) go to its status line.
$global:VanillaReport = { param($text, $fraction) Set-Status $text }

# The window's icon: the crest.
function Set-Icon {
    $ui.Crest.Measure((New-Object Windows.Size 78, 78))
    $ui.Crest.Arrange((New-Object Windows.Rect 0, 0, 78, 78))
    $bmp = New-Object Windows.Media.Imaging.RenderTargetBitmap 96, 96, 96, 96, ([Windows.Media.PixelFormats]::Pbgra32)
    $bmp.Render($ui.Crest)
    $window.Icon = [Windows.Media.Imaging.BitmapFrame]::Create($bmp)
}

if ($CheckOnly) {
    # The window's check with no window: what it reported, for the tests.
    $sync.Clear(); $sync.message = ''; $sync.fraction = -1.0; $sync.reports = 0; $sync.done = $false
    $ps = [PowerShell]::Create()
    $ps.Runspace = [RunspaceFactory]::CreateRunspace()
    $ps.Runspace.Open()
    $ps.Runspace.SessionStateProxy.SetVariable('sync', $sync)
    [void]$ps.AddScript($work).AddArgument($kitDir).AddArgument('check').AddArgument(@{ Settings = (Read-Settings) })
    $handle = $ps.BeginInvoke()
    $top = 0.0
    while (-not $sync.done) {
        Start-Sleep -Milliseconds 30
        if ($sync.fraction -gt $top) { $top = [double]$sync.fraction }
    }
    try { [void]$ps.EndInvoke($handle) } catch { }
    $ps.Runspace.Dispose()
    $ps.Dispose()
    $r = $sync.result
    $art = Update-Art (Read-Settings)
    Write-Host ("launcher check: realm {0}, status {1}, version {2}, {3} reports, progress {4:N2}, error {5}, art {6}" -f
        $sync.realm, $r.Status, $r.Version, $sync.reports, $top, $sync.error, $art)
    return
}

$s0 = Read-Settings
if ($Look -ne 'plain' -and (Test-Art $s0)) { [void](Set-WowLook) }

if ($Snapshot) {
    # A picture of the window, for the guide and for checking the look; nothing is checked or started.
    $news = Read-News
    if ($Demo) {
        if (@($news).Count -eq 0) {
            $news = @(
                [pscustomobject]@{ version = '2026.10.15.3'; notes = 'Play on your own: Settings, On my own, and the launcher builds a realm of your own on your PC, logs you in, and asks how it went when you are done.' },
                [pscustomobject]@{ version = '2026.10.15.2'; notes = 'Voice chat is built in: players near you hear you from where your character stands.' },
                [pscustomobject]@{ version = '2026.10.15.1'; notes = 'Every class plays by body: finishers on B, a loop in the air for crowd control, a hand along the blade for poison.' }
            )
        }
        Set-Realm 'online' '100.101.102.103'
        $ui.VersionText.Text = '2026.10.15.3'
        $ui.VrDot.Fill = Brush $colors.Green
        $ui.VrText.Text = 'SteamVR is running'
        $ui.RollbackBtn.IsEnabled = $true
        if ($Page -eq 'ready') {
            Set-Status 'Up to date. Ready to play.' $colors.Green
            $ui.Progress.Value = 1
        } elseif ($Page -eq 'build') {
            Set-Realm 'building' 'on this PC'
            Set-Status 'Building your realm: pathfinding (48%, about 21 min left)...'
            $ui.Progress.Value = 0.71
            $ui.PlayBtn.IsEnabled = $false
        } else {
            Set-Status 'Downloading benilla-vr.exe... 62%'
            $ui.Progress.Value = 0.62
            $ui.PlayBtn.IsEnabled = $false
        }
    } else {
        Set-Realm $(if (Test-Solo $s0) { 'asleep' } elseif ($s0['SERVER']) { 'checking' } else { 'unset' }) $s0['SERVER']
        Show-Version
        Show-Headset
    }
    Show-News $news
    if ($Page -eq 'settings') {
        Show-Settings
        if ($Demo) {
            $ui.GameBox.Text = 'C:\Games\World of Warcraft 1.12.1'
            $ui.ServerBox.Text = '100.101.102.103'
            $ui.NameBox.Text = 'Thrall'
            $ui.CancelBtn.IsEnabled = $true
        }
    }
    if ($Page -eq 'rollback') {
        Show-Confirm 'GO BACK A VERSION' 'Go back to 2026.10.15.2? The version you have now (2026.10.15.3) won''t be installed again; the next one will.' 'Go back' 'Cancel' $null
    }
    if ($Page -eq 'feedback') {
        Show-Feedback
        if ($Demo) {
            $ratings['Fun'][3].IsChecked = $true
            $ratings['Works'][2].IsChecked = $true
            $ratings['Body'][4].IsChecked = $true
            $ui.GreatBox.Text = 'Charging into a pack and swinging for real. Loot by hand never gets old.'
            $ui.BrokeBox.Text = 'Sunder fired twice when I only meant to block.'
        }
    }
    $root = $window.Content
    $root.Measure((New-Object Windows.Size 940, 600))
    $root.Arrange((New-Object Windows.Rect 0, 0, 940, 600))
    $root.UpdateLayout()
    $bmp = New-Object Windows.Media.Imaging.RenderTargetBitmap 1880, 1200, 192, 192, ([Windows.Media.PixelFormats]::Pbgra32)
    $bmp.Render($root)
    $enc = New-Object Windows.Media.Imaging.PngBitmapEncoder
    $enc.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bmp))
    $fs = [IO.File]::Create($Snapshot)
    try { $enc.Save($fs) } finally { $fs.Dispose() }
    Write-Host "launcher: drew $Snapshot ($script:worn look)$(if ($script:lookError) { "; the game's look failed: $script:lookError" })"
    return
}

try { Set-Icon } catch { }
Show-News (Read-News)
Show-Version
Show-Headset
if (Test-Solo $s0) { Show-SoloRealm }
$window.Add_ContentRendered({ Start-Check; $timer.Start() })
$window.Add_Closing({
        param($sender, $e)
        if ($script:session) { $e.Cancel = $true; $window.Hide(); return }
        $window.Hide()
        $timer.Stop()
        # A build stops here and carries on next time; a realm left awake goes to sleep.
        if ($script:job) {
            try { $script:job.ps.Stop(); $script:job.ps.Dispose() } catch { }
            Get-Process -Name 'MapExtractor', 'VMapExtractor', 'VMapAssembler', 'MoveMapGenerator', 'mariadb' -ErrorAction SilentlyContinue |
                Where-Object { $_.Path -and $_.Path.StartsWith((Join-Path $kitDir 'solo'), [StringComparison]::OrdinalIgnoreCase) } |
                Stop-Process -Force -ErrorAction SilentlyContinue
        }
        if (-not $script:closing -and (Test-Path (Join-Path $kitDir 'solo\solo.json'))) {
            try { if (Get-SoloProcesses) { Stop-Solo } } catch { }
        }
        # A session's report still waiting is written now; the next check sends it.
        $last = $script:lastSession
        if ($last -and -not (Test-Path (Join-Path $kitDir "logs\session-$($last.Stamp).json"))) {
            try { [void](New-SessionReport $last) } catch { }
        }
    })
$window.Add_Closed({ [Windows.Threading.Dispatcher]::CurrentDispatcher.InvokeShutdown() })
$window.Show()
[Windows.Threading.Dispatcher]::Run()
