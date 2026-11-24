. (Join-Path $PSScriptRoot 'hotd-game-library.ps1')
function Show-Hotd4SPStartMenu {
    param(
        [Parameter(Mandatory)] [string] $RecompDir,
        [Parameter(Mandatory)] [int] $DesktopWidth,
        [Parameter(Mandatory)] [int] $DesktopHeight,
        [string] $InitialPage = 'MainPage'
    )

    . (Join-Path $RecompDir 'hotd4-display.ps1')
    . (Join-Path $RecompDir 'hotd4sp-config.ps1')
    $spIni = Read-Hotd4SPConfig $RecompDir
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
    [xml] $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="The House of the Dead 4 Special" WindowStyle="None"
        ResizeMode="NoResize" WindowStartupLocation="Manual"
        Background="#08090B" Foreground="#F0EFEB" FontFamily="Segoe UI"
        Left="0" Top="0" Topmost="True" UseLayoutRounding="True">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Foreground" Value="#F0EFEB"/>
            <Setter Property="Background" Value="#AB181A20"/>
            <Setter Property="FontSize" Value="21"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Height" Value="50"/>
            <Setter Property="Margin" Value="0,0,0,9"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="Padding" Value="19,0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Surface" Background="{TemplateBinding Background}"
                                BorderBrush="#80585960" BorderThickness="1">
                            <ContentPresenter Margin="{TemplateBinding Padding}" VerticalAlignment="Center"
                                              HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"
                                              RecognizesAccessKey="True"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Surface" Property="Background" Value="#D77A2127"/>
                                <Setter TargetName="Surface" Property="BorderBrush" Value="#FA745C"/>
                            </Trigger>
                            <Trigger Property="IsKeyboardFocused" Value="True">
                                <Setter TargetName="Surface" Property="Background" Value="#D77A2127"/>
                                <Setter TargetName="Surface" Property="BorderBrush" Value="#FA745C"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Surface" Property="Background" Value="#A13936"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="ChapterButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Height" Value="44"/>
            <Setter Property="FontSize" Value="18"/>
            <Setter Property="Margin" Value="0,0,0,7"/>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Height" Value="44"/>
            <Setter Property="FontSize" Value="18"/>
            <Setter Property="Margin" Value="0,6,0,21"/>
            <Setter Property="Padding" Value="12,0,6,0"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Foreground" Value="#F0EFEB"/>
            <Setter Property="Background" Value="#25252D"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton Focusable="False" ClickMode="Press"
                                IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
                                <ToggleButton.Template>
                                    <ControlTemplate TargetType="ToggleButton">
                                        <Border Background="#25252D" BorderThickness="1" BorderBrush="#80717A">
                                            <Path Data="M 0 0 L 5 5 L 10 0" Stroke="#F0EFEB" StrokeThickness="1.5"
                                                  HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,15,0"/>
                                        </Border>
                                    </ControlTemplate>
                                </ToggleButton.Template>
                            </ToggleButton>
                            <ContentPresenter x:Name="Selection" IsHitTestVisible="False" Margin="12,0,35,0" VerticalAlignment="Center"
                                Content="{TemplateBinding SelectionBoxItem}"
                                ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"/>
                            <TextBox x:Name="PART_EditableTextBox" Visibility="Collapsed" Margin="11,1,32,1" Padding="0"
                                     VerticalContentAlignment="Center" Background="Transparent" BorderThickness="0"
                                     Foreground="{TemplateBinding Foreground}" CaretBrush="#F0EFEB"
                                     IsReadOnly="{TemplateBinding IsReadOnly}"/>
                            <Border x:Name="FocusBorder" IsHitTestVisible="False" BorderBrush="Transparent" BorderThickness="1"/>
                            <Popup Name="PART_Popup" Placement="Bottom" AllowsTransparency="True"
                                   IsOpen="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}" Focusable="False">
                                <Border Background="#25252D" BorderBrush="#80717A" BorderThickness="1"
                                        MinWidth="{Binding ActualWidth, RelativeSource={RelativeSource TemplatedParent}}">
                                    <ScrollViewer MaxHeight="{TemplateBinding MaxDropDownHeight}">
                                        <ItemsPresenter KeyboardNavigation.DirectionalNavigation="Contained"/>
                                    </ScrollViewer>
                                </Border>
                            </Popup>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsEditable" Value="True">
                                <Setter TargetName="Selection" Property="Visibility" Value="Collapsed"/>
                                <Setter TargetName="PART_EditableTextBox" Property="Visibility" Value="Visible"/>
                            </Trigger>
                            <Trigger Property="IsKeyboardFocusWithin" Value="True">
                                <Setter TargetName="FocusBorder" Property="BorderBrush" Value="#FA745C"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ComboBoxItem">
            <Setter Property="Foreground" Value="#F0EFEB"/>
            <Setter Property="Padding" Value="12,8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBoxItem">
                        <Border x:Name="Item" Background="Transparent" Padding="{TemplateBinding Padding}">
                            <ContentPresenter/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsHighlighted" Value="True">
                                <Setter TargetName="Item" Property="Background" Value="#7A2127"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Name="Backdrop">
        <Rectangle>
            <Rectangle.Fill>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                    <GradientStop Color="#1708080B" Offset="0"/>
                    <GradientStop Color="#3308080B" Offset="0.39"/>
                    <GradientStop Color="#DF08080B" Offset="0.68"/>
                    <GradientStop Color="#FC08080B" Offset="1"/>
                </LinearGradientBrush>
            </Rectangle.Fill>
        </Rectangle>
        <Rectangle>
            <Rectangle.Fill>
                <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                    <GradientStop Color="#4208080B" Offset="0"/>
                    <GradientStop Color="#0008080B" Offset="0.25"/>
                    <GradientStop Color="#0608080B" Offset="0.62"/>
                    <GradientStop Color="#D508080B" Offset="1"/>
                </LinearGradientBrush>
            </Rectangle.Fill>
        </Rectangle>

        <Viewbox Stretch="Uniform">
            <Grid Width="1280" Height="720" KeyboardNavigation.TabNavigation="Cycle">
                <Border Name="InputGuide" Visibility="Collapsed" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="160,120,0,0" Width="440" Background="#ED101218" BorderBrush="#575962" BorderThickness="1" Padding="24">
                    <StackPanel>
                        <TextBlock Text="Input Setup" FontSize="22" Margin="0,0,0,18"/>
                        <TextBlock Name="GeneralInputHelp" Text="To escape a grab with a mouse, shake left/right or up/down. Reload does not break grabs. For Sinden, select Lightgun (Raw Input) and enable the white border in Settings. Start the Sinden software before playing." TextWrapping="Wrap" FontSize="17" Foreground="#D0C7C2" Margin="0,0,0,16"/>
                        <TextBlock Name="CoopGuide" Text="For Parsec co-op, choose Gun P1 + Mouse P2 and select the host's Sinden or DolphinBar as P1. The guest's injected mouse controls P2 automatically. Disable Exclusive Input in Parsec and join with P2 Coin / Start. For two local guns, use Lightgun (Raw Input) and select both devices." TextWrapping="Wrap" FontSize="17" Foreground="#D0C7C2" Margin="0,0,0,16"/>
                        <TextBlock Name="AaGuide" Text="Restart the game to apply input, AA and V-sync changes. V-sync affects desktop output; VR uses headset timing. If the GPU cannot create the selected MSAA mode, the game falls back to Off." TextWrapping="Wrap" FontSize="17" Foreground="#D0C7C2"/>
                    </StackPanel>
                </Border>
                <Border Name="CrosshairPreview" Width="440" Height="324" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="160,268,0,0" Background="#F0101218" BorderBrush="#80585960" BorderThickness="1" Visibility="Collapsed" IsHitTestVisible="False">
                    <StackPanel>
                        <TextBlock Text="Crosshair Preview" Foreground="#D0C7C2" FontSize="18" HorizontalAlignment="Center" Margin="0,18,0,0"/>
                        <Image Name="CrosshairPreviewImage" Width="320" Height="240" Stretch="None"/>
                        <TextBlock Name="CrosshairPreviewLabel" Foreground="#F0EFEB" FontSize="16" HorizontalAlignment="Center"/>
                    </StackPanel>
                </Border>
                <StackPanel Width="398" HorizontalAlignment="Right" Margin="0,65,74,0">
                    <TextBlock FontSize="24" FontWeight="SemiBold" Text="THE HOUSE OF THE"/>
                    <StackPanel Orientation="Horizontal" Margin="0,-5,0,16">
                        <TextBlock FontSize="58" FontWeight="Black" Text="DEAD"/>
                        <TextBlock FontSize="58" FontWeight="Black" Text="4" Foreground="#F07460" Margin="17,0,0,0"/>
                        <TextBlock Text="SPECIAL" Foreground="#E8B66D" FontSize="18" VerticalAlignment="Bottom" Margin="12,0,0,18"/>
                    </StackPanel>
                    <Rectangle Height="2" Fill="#BA383C" Width="66" HorizontalAlignment="Left" Margin="0,0,0,22"/>

                    <StackPanel Name="MainPage">
                        <Button Name="Arcade" Content="Play Arcade"/>
                        <Button Name="Chapters" Content="Chapter Select"/>
                        <Button Name="PlayLogged" Content="Play with Frame Logging"/>
                        <Button Name="Options" Content="Settings"/>
                        <Button Name="Quit" Content="Quit"/>
                    </StackPanel>

                    <StackPanel Name="ChapterPage" Visibility="Collapsed">
                        <TextBlock Text="Chapter Select" FontSize="22" FontWeight="SemiBold" Margin="0,0,0,8"/>
                        <TextBlock Name="ChapterHelp" Text="Practice mode" Foreground="#D0C7C2" FontSize="15" Margin="0,0,0,15"/>
                        <StackPanel Name="ChapterList"/>
                        <Button Name="ChapterBack" Content="Back" Style="{StaticResource ChapterButton}"/>
                    </StackPanel>

                    <StackPanel Name="OptionsPage" Visibility="Collapsed">
                        <TextBlock Text="Settings" FontSize="22" FontWeight="SemiBold" Margin="0,0,0,10"/>
                        <Grid>
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="156"/></Grid.ColumnDefinitions>
                            <StackPanel Margin="0,0,12,0">
                                <Label Content="Render Resolution" Foreground="#F0EFEB" FontSize="15" Padding="0" Target="{Binding ElementName=Resolution}"/>
                                <ComboBox Height="36" Margin="0,4,0,6" Name="Resolution" IsEditable="True"
                                          ToolTip="Choose a preset or enter a resolution such as 2560x1440."
                                          AutomationProperties.Name="Render Resolution"/>
                            </StackPanel>
                            <StackPanel Grid.Column="1">
                                <Label Content="Display Mode" Foreground="#F0EFEB" FontSize="15" Padding="0" Target="{Binding ElementName=DisplayMode}"/>
                                <ComboBox Height="36" Margin="0,4,0,6" Name="DisplayMode" AutomationProperties.Name="Display Mode"/>
                            </StackPanel>
                        </Grid>
                        <CheckBox Name="CrosshairEnabled" Content="Show Crosshair" Foreground="#F0EFEB" FontSize="15" Margin="0,0,0,5"/>
                        <Grid>
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="156"/></Grid.ColumnDefinitions>
                            <StackPanel Margin="0,0,12,0">
                                <Label Content="Player HUD Scale" Foreground="#F0EFEB" FontSize="15" Padding="0" Target="{Binding ElementName=Hud}"/>
                                <ComboBox Height="36" Margin="0,4,0,6" Name="Hud" AutomationProperties.Name="HUD"/>
                            </StackPanel>
                            <StackPanel Grid.Column="1">
                                <Label Content="Aspect Ratio" Foreground="#F0EFEB" FontSize="15" Padding="0" Target="{Binding ElementName=Aspect}"/>
                                <ComboBox Name="Aspect" Height="36" Margin="0,4,0,6" AutomationProperties.Name="Aspect Ratio" ToolTip="Save, exit and relaunch the game to apply. 4:3 uses side bars on wider displays. VR keeps its headset view."/>
                            </StackPanel>
                        </Grid>
                        <Grid>
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="120"/></Grid.ColumnDefinitions>
                            <StackPanel Margin="0,0,12,0">
                                <Label Content="Crosshair Style" Foreground="#F0EFEB" FontSize="15" Padding="0" Target="{Binding ElementName=CrosshairStyle}"/>
                                <ComboBox Height="36" Margin="0,4,0,6" Name="CrosshairStyle" AutomationProperties.Name="Crosshair Style"/>
                            </StackPanel>
                            <StackPanel Grid.Column="1">
                                <Label Content="Size" Foreground="#F0EFEB" FontSize="15" Padding="0" Target="{Binding ElementName=CrosshairSize}"/>
                                <ComboBox Height="36" Margin="0,4,0,6" Name="CrosshairSize" AutomationProperties.Name="Crosshair Size"/>
                            </StackPanel>
                        </Grid>
                        <Grid>
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="208"/></Grid.ColumnDefinitions>
                            <StackPanel Margin="0,0,12,0">
                                <Label Content="Crosshair Color" Foreground="#F0EFEB" FontSize="15" Padding="0" Target="{Binding ElementName=CrosshairColor}"/>
                                <ComboBox Height="36" Margin="0,4,0,6" Name="CrosshairColor" AutomationProperties.Name="Crosshair Color"/>
                            </StackPanel>
                            <StackPanel Grid.Column="1">
                                <Label Content="Sinden Border / Thickness" Foreground="#F0EFEB" FontSize="15" Padding="0" Target="{Binding ElementName=Sinden}"/>
                                <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="72"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                                    <ComboBox Height="36" FontSize="14" Margin="0,4,5,6" Name="Sinden" AutomationProperties.Name="Sinden Lightgun Border"/>
                                    <ComboBox Grid.Column="1" Height="36" FontSize="12" Margin="0,4,0,6" Name="SindenWidth" AutomationProperties.Name="Sinden Border Thickness"/>
                                </Grid>
                            </StackPanel>
                        </Grid>
                        <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="130"/><ColumnDefinition Width="105"/></Grid.ColumnDefinitions>
                            <Button Name="InputOptions" Height="32" FontSize="14" Margin="0,0,6,6" Content="Graphics / Input..."/>
                            <Button Grid.Column="1" Name="BindingsOpen" Height="32" FontSize="14" Margin="0,0,0,6" Content="Key Bindings..."/>
                            <Button Grid.Column="2" Name="GameplayOpen" Height="32" FontSize="14" Padding="8,0" Margin="6,0,0,6" Content="Gameplay..."/>
                        </Grid>
                        <Grid>
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                            <Button Name="SaveOptions" Height="38" Margin="0,0,6,6" Content="Save"/>
                            <Button Name="Performance720p" Grid.Column="1" Height="38" Margin="0,0,0,6" FontSize="15" Padding="10,0"
                                    Content="Apply 720p Performance" ToolTip="Saves 1280x720 render resolution and turns off MSAA and anisotropic filtering."/>
                        </Grid>
                        <Button Name="OptionsBack" Height="38" Content="Back"/>
                    </StackPanel>
                    <StackPanel Name="GameplayPage" Visibility="Collapsed">
                        <TextBlock Text="Gameplay" FontSize="22" FontWeight="SemiBold" Margin="0,0,0,12"/>
                        <Label Content="Rules" Foreground="#F0EFEB" FontSize="15" Padding="0" Target="{Binding ElementName=HomeMode}"/>
                        <ComboBox Name="HomeMode" Height="36" Margin="0,4,0,6"
                                  ToolTip="Home uses individual lives, manual reload, and smooth ride transitions."/>
                        <Label Content="Solo Player" Foreground="#F0EFEB" FontSize="15" Padding="0"/>
                        <ComboBox Name="SoloPlayer" Height="36" Margin="0,4,0,6"/>
                        <TextBlock Name="SoloPlayerHint" Text="Your mouse or lightgun follows your character." TextWrapping="Wrap" FontSize="13" Foreground="#ADB4C2" Margin="0,0,0,6"/>
                        <Label Content="Lightgun Off-Screen Reload" Foreground="#F0EFEB" FontSize="15" Padding="0"/>
                        <ComboBox Height="36" Margin="0,4,0,8" Name="OffscreenReload"/>
                        <TextBlock Text="Aim off-screen and pull the trigger. Applies to both lightguns." TextWrapping="Wrap" Foreground="#D0C7C2" FontSize="14" Margin="0,0,0,10"/>
                        <Label Content="Blood Splatter" Foreground="#F0EFEB" FontSize="15" Padding="0"/>
                        <ComboBox Height="36" Margin="0,4,0,8" Name="BloodSplatter"/>
                        <CheckBox Name="FreePlay" Content="Free Play (unlimited credits)" Foreground="#F0EFEB" FontSize="15" Margin="0,4,0,8" ToolTip="Use Start and Continue without coins. Applies when the game starts."/>
                        <CheckBox Name="MuteCreditSounds" Content="Mute Start and coin sounds" Foreground="#F0EFEB" FontSize="15" Margin="0,0,0,12" ToolTip="Applies when the game starts."/>
                        <Button Name="SaveGameplay" Height="38" Margin="0,0,0,6" Content="Save"/>
                        <Button Name="GameplayBack" Height="38" Content="Back"/>
                    </StackPanel>
                    <StackPanel Name="InputPage" Visibility="Collapsed">
                        <TextBlock Text="Graphics, Audio &amp; Input" FontSize="22" FontWeight="SemiBold" Margin="0,0,0,12"/>
                        <ScrollViewer MaxHeight="350" VerticalScrollBarVisibility="Auto"><StackPanel>
                        <Label Content="16:9 Gameplay Framing" Foreground="#F0EFEB" FontSize="15" Padding="0" Target="{Binding ElementName=Framing}"/>
                        <ComboBox Name="Framing" Height="36" Margin="0,4,0,6"
                                  ToolTip="Choose the arcade view whose height stays visible. Both options extend the sides to 16:9."/>
                        <Label Content="Input Mode" Foreground="#F0EFEB" FontSize="15" Padding="0" Target="{Binding ElementName=InputMode}"/>
                        <ComboBox Height="36" Margin="0,4,0,6" Name="InputMode"/>
                        <TextBlock Name="KeyboardHelp" Text="Keyboard mode: P1 arrows + Right Ctrl / Right Shift / Right Alt; P2 WASD + Space / Q / E. Customize movement and actions in Key Bindings. Service: F10." TextWrapping="Wrap" FontSize="13" Foreground="#E9C38A" Margin="0,0,0,10" Visibility="Collapsed"/>
                        <Label Name="Gun1Label" Content="Player 1 Device" Foreground="#F0EFEB" FontSize="15" Padding="0" Target="{Binding ElementName=Gun1}"/>
                        <ComboBox Height="36" Margin="0,4,0,6" Name="Gun1"/>
                        <Label Name="Gun2Label" Content="Player 2 Device" Foreground="#F0EFEB" FontSize="15" Padding="0" Target="{Binding ElementName=Gun2}"/>
                        <ComboBox Height="36" Margin="0,4,0,6" Name="Gun2"/>
                        <Label Content="Anti-Aliasing" Foreground="#F0EFEB" FontSize="15" Padding="0" Target="{Binding ElementName=AntiAliasing}"/>
                        <ComboBox Height="36" Margin="0,4,0,8" Name="AntiAliasing"/>
                        <Label Content="V-Sync" Foreground="#F0EFEB" FontSize="15" Padding="0" Target="{Binding ElementName=VSync}"/>
                        <ComboBox Height="36" Margin="0,4,0,8" Name="VSync" ToolTip="Desktop display synchronization. Restart the game to apply. VR uses headset timing."/>
                        <Grid Margin="0,0,0,6"><Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
                            <StackPanel Margin="0,0,5,0">
                                <Label Content="Mouse Speed" Foreground="#F0EFEB" FontSize="15" Padding="0" Target="{Binding ElementName=MouseSpeed}"/>
                                <ComboBox Height="36" Margin="0,4,0,0" Name="MouseSpeed"/>
                            </StackPanel>
                            <StackPanel Grid.Column="1">
                                <Label Content="Mouse Smoothing" Foreground="#F0EFEB" FontSize="15" Padding="0" Target="{Binding ElementName=MouseSmoothing}"/>
                                <ComboBox Height="36" Margin="0,4,0,0" Name="MouseSmoothing"/>
                            </StackPanel>
                        </Grid>
                        <Grid><Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
                            <StackPanel Margin="0,0,6,0"><Label Content="Anisotropic Filtering" Foreground="#F0EFEB" FontSize="15" Padding="0"/><ComboBox Name="Anisotropy" Height="36" Margin="0,4,0,8"/></StackPanel>
                            <StackPanel Grid.Column="1"><Label Content="Volume" Foreground="#F0EFEB" FontSize="15" Padding="0"/><ComboBox Name="Volume" Height="36" Margin="0,4,0,8"/></StackPanel>
                        </Grid>
                        <CheckBox Name="MouseGrab" Content="Lock mouse to the game window" Foreground="#F0EFEB" FontSize="15" Margin="0,7,0,7"/>
                        <CheckBox Name="LeaveReload" Content="Reload when the pointer leaves the window" Foreground="#F0EFEB" FontSize="15" Margin="0,0,0,10"/>
                        </StackPanel></ScrollViewer>
                        <Button Name="SaveInput" Height="38" Margin="0,0,0,6" Content="Save"/>
                        <Button Name="InputBack" Height="38" Content="Back"/>
                    </StackPanel>
                </StackPanel>
                <Border Name="ControlSummary" Visibility="Visible" HorizontalAlignment="Left" VerticalAlignment="Bottom" Width="660" Margin="74,0,0,64" Background="#C810141B" BorderBrush="#655B5146" BorderThickness="1" Padding="18,14">
                    <StackPanel>
                        <TextBlock Text="IN-GAME CONTROLS" FontSize="14" FontWeight="SemiBold" Foreground="#E9C38A" Margin="0,0,0,12"/>
                        <UniformGrid Name="ControlSummaryList" Rows="8" Columns="2"/>
                        <TextBlock Text="Change controls in Settings &gt; Key Bindings. Shake the mouse to escape grabs." FontSize="12" Foreground="#ADB4C2" Margin="0,9,0,0"/>
                    </StackPanel>
                </Border>
                <Border Name="BindingsPage" Visibility="Collapsed" Margin="64,60,64,60" Background="#FC0B0E14" BorderBrush="#686052" BorderThickness="1" Padding="26,22">
                    <Grid>
                        <Grid.RowDefinitions><RowDefinition Height="76"/><RowDefinition Height="*"/><RowDefinition Height="48"/><RowDefinition Height="42"/></Grid.RowDefinitions>
                        <StackPanel>
                            <TextBlock Text="KEY BINDINGS" FontSize="32" FontWeight="Bold"/>
                            <TextBlock Text="Select an action, then press your preferred key. Save applies your changes." Foreground="#ADB4C2" FontSize="14" Margin="0,8,0,0"/>
                        </StackPanel>
                        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto"><StackPanel Name="BindingsList"/></ScrollViewer>
                        <TextBlock Grid.Row="2" Name="BindingsStatus" TextWrapping="Wrap" Foreground="#E9C38A" FontSize="13" VerticalAlignment="Center"/>
                        <Grid Grid.Row="3">
                            <StackPanel Orientation="Horizontal">
                                <Button Name="ResetBindings" Content="Reset Defaults" FontSize="16" Width="180" Height="38" Margin="0,0,12,0"/>
                                <Button Name="CancelBinding" Content="Cancel Capture" Visibility="Collapsed" FontSize="16" Width="190" Height="38"/>
                            </StackPanel>
                            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                                <Button Name="SaveBindings" Content="Save" FontSize="16" Width="140" Height="38" Margin="0,0,12,0"/>
                                <Button Name="BindingsBack" Content="Back" FontSize="16" Width="140" Height="38"/>
                            </StackPanel>
                        </Grid>
                    </Grid>
                </Border>

                <TextBlock Name="Hint" FontSize="15" Foreground="#D0C7C2" HorizontalAlignment="Right"
                           VerticalAlignment="Bottom" Margin="0,0,74,26"/>
            </Grid>
        </Viewbox>
        <Border Name="SindenFrame" BorderBrush="White" Visibility="Collapsed" IsHitTestVisible="False">
            <Border Name="SindenInner" BorderBrush="Black"/>
        </Border>
    </Grid>
</Window>
"@
    # WPF requires the XAML namespace for control-template names.
    $window = [Windows.Markup.XamlReader]::Load([Xml.XmlNodeReader]::new($xaml))
    $window.Width = [Windows.SystemParameters]::PrimaryScreenWidth
    $window.Height = [Windows.SystemParameters]::PrimaryScreenHeight
    $background = Join-Path $RecompDir 'hotd4sp-menu.jpg'
    if ([IO.File]::Exists($background)) {
        $brush = [Windows.Media.ImageBrush]::new([Windows.Media.Imaging.BitmapImage]::new([uri]$background))
        $brush.Stretch = 'UniformToFill'
        $brush.AlignmentX = 'Left'
        $brush.Viewbox = [Windows.Rect]::new(0.12, 0.03, 0.82, 0.89)
        $window.FindName('Backdrop').Background = $brush
    }

    $controls = @{}
    foreach ($name in 'MainPage','ChapterPage','OptionsPage','Arcade','Chapters','Options','Quit','ChapterList','Performance720p',
            'Gun1Label','SoloPlayer','SoloPlayerHint','GameplayPage','GameplayOpen','HomeMode','OffscreenReload','BloodSplatter','FreePlay','MuteCreditSounds','SaveGameplay','GameplayBack','Gun2Label','BindingsPage','BindingsOpen','BindingsList','BindingsStatus','SaveBindings','BindingsBack','ResetBindings','CancelBinding','ControlSummary','ControlSummaryList','ChapterHelp','AaGuide','PlayLogged','CrosshairEnabled','Anisotropy','Volume','MouseGrab','LeaveReload','InputGuide','InputPage','InputOptions','Framing','InputMode','GeneralInputHelp','KeyboardHelp','CoopGuide','Gun1','Gun2','AntiAliasing','VSync','Aspect','MouseSpeed','MouseSmoothing','SaveInput','InputBack','ChapterBack','OptionsBack','SaveOptions','Resolution','DisplayMode','Hud','CrosshairStyle','CrosshairSize','CrosshairColor','CrosshairPreview','CrosshairPreviewImage','CrosshairPreviewLabel','Sinden','SindenWidth','SindenFrame','SindenInner','Hint') {
        $controls[$name] = $window.FindName($name)
    }

    $hudPath = Join-Path $RecompDir 'hud-profile.txt'
    $resolutionPath = Join-Path $RecompDir 'display-profile.txt'
    $displayModePath = Join-Path $RecompDir 'display-mode.txt'
    $sindenPath = Join-Path $RecompDir 'sinden-profile.txt'
    $sindenWidthPath = Join-Path $RecompDir 'sinden-width.txt'
    $state = @{ LogFrames=$false; SindenWidth='50'; Mode = $null; Hud = '0'; Resolution = 'auto'; DisplayMode = 'Borderless'; Sinden = '0'; Crosshair = '0'; CrosshairSize = '100'; CrosshairColor = '0' }
    if ([IO.File]::Exists($sindenPath) -and [IO.File]::ReadAllText($sindenPath).Trim() -eq '1') { $state.Sinden = '1' }
    $crosshairPath = Join-Path $RecompDir 'crosshair-profile.txt'
    if ([IO.File]::Exists($crosshairPath)) {
        $saved = [IO.File]::ReadAllText($crosshairPath).Trim()
        if ($saved -match '^[0-3]$') { $state.Crosshair = $saved }
    }
    $crosshairColorPath = Join-Path $RecompDir 'crosshair-color.txt'
    if ([IO.File]::Exists($crosshairColorPath)) {
        $saved = [IO.File]::ReadAllText($crosshairColorPath).Trim()
        if ($saved -match '^[0-8]$') { $state.CrosshairColor = $saved }
    }
    $colors = @('Original','Red','Blue','Green','Yellow','White','Cyan','Magenta','Orange')
    foreach ($index in 0..8) {
        $item = [Windows.Controls.ComboBoxItem]::new()
        $item.Content = $colors[$index]; $item.Tag = [string]$index
        [void] $controls.CrosshairColor.Items.Add($item)
    }
    $crosshairSizePath = Join-Path $RecompDir 'crosshair-size.txt'
    if ([IO.File]::Exists($crosshairSizePath)) {
        $saved = [IO.File]::ReadAllText($crosshairSizePath).Trim()
        if ($saved -in @('50','75','100','125','150','175','200')) { $state.CrosshairSize = $saved }
    }
    foreach ($percent in 50,75,100,125,150,175,200) {
        $item = [Windows.Controls.ComboBoxItem]::new()
        $item.Content = "$percent %"; $item.Tag = [string]$percent
        [void] $controls.CrosshairSize.Items.Add($item)
    }
    $styles = @('Original Red','Blue Circle','Red Square','Name Entry (Original)')
    foreach ($index in 0..3) {
        $item = [Windows.Controls.ComboBoxItem]::new()
        $item.Content = $styles[$index]; $item.Tag = [string]$index
        [void] $controls.CrosshairStyle.Items.Add($item)
    }
    if([IO.File]::Exists($sindenWidthPath)){$saved=[IO.File]::ReadAllText($sindenWidthPath).Trim();if($saved -in '25','50','75','100'){$state.SindenWidth=$saved}}
    $updateSindenBorder = {
        $scale=[int]$state.SindenWidth/100.0
        $edge = [Math]::Max([Math]::Ceiling(8*$scale), [Math]::Ceiling([Math]::Min($window.Width, $window.Height) * 0.03*$scale))
        $inner = [Math]::Max([Math]::Ceiling(2*$scale), [Math]::Ceiling([Math]::Min($window.Width, $window.Height) * 0.005*$scale))
        $controls.SindenFrame.BorderThickness = [Windows.Thickness]::new($edge)
        $controls.SindenInner.BorderThickness = [Windows.Thickness]::new($inner)
        $controls.SindenFrame.Visibility = if ($state.Sinden -eq '1') { 'Visible' } else { 'Collapsed' }
    }
    & $updateSindenBorder
    foreach ($key in '0','1') {
        $item = [Windows.Controls.ComboBoxItem]::new()
        $item.Content = if ($key -eq '1') { 'On' } else { 'Off' }
        $item.Tag = $key
        [void] $controls.Sinden.Items.Add($item)
    }
    foreach($entry in @(@('25','0.75% Extra Thin'),@('50','1.5% Default'),@('75','2.25% Medium'),@('100','3% Original'))){
        $item=[Windows.Controls.ComboBoxItem]::new();$item.Tag=$entry[0];$item.Content=$entry[1];[void]$controls.SindenWidth.Items.Add($item)
    }
    $controls.SindenWidth.Add_SelectionChanged({if($controls.SindenWidth.SelectedItem){$savedWidth=$state.SindenWidth;$state.SindenWidth=[string]$controls.SindenWidth.SelectedItem.Tag;& $updateSindenBorder;$state.SindenWidth=$savedWidth}})
    if ([IO.File]::Exists($hudPath)) {
        $saved = [IO.File]::ReadAllText($hudPath).Trim()
        if ($saved -match '^(0|75|100|125)$') { $state.Hud = $saved }
    }
    if ([IO.File]::Exists($resolutionPath)) {
        $saved = ConvertTo-Hotd4Resolution ([IO.File]::ReadAllText($resolutionPath))
        if ($saved) {
            $state.Resolution = $saved
            if ($saved -ne 'auto') { $state.DisplayMode = 'Windowed' }
        }
    }
    if(![IO.File]::Exists($resolutionPath)){$state.Resolution="$($spIni.width)x$($spIni.height)";$state.DisplayMode=if([int]$spIni.fullscreen){'Borderless'}else{'Windowed'}}
    if ([IO.File]::Exists($displayModePath)) {
        $saved = [IO.File]::ReadAllText($displayModePath).Trim()
        if ($saved -in 'Borderless','Windowed') { $state.DisplayMode = $saved }
    }
    $controls.Resolution.ItemsSource = @('Desktop','960x540','1280x720','1366x768','1600x900','1920x1080',
                                        '2560x1440','3200x1800','3840x2160')
    $controls.Resolution.ToolTip = "Desktop is $DesktopWidth × $DesktopHeight. Choose a preset or enter width x height."
    $controls.DisplayMode.ItemsSource = @('Borderless','Windowed')
    foreach ($key in '0','75','100','125') {
        $item = [Windows.Controls.ComboBoxItem]::new()
        $item.Tag = $key
        $item.Content = if ($key -eq '0') { 'Original' } else { "$key %" }
        [void] $controls.Hud.Items.Add($item)
    }

    if ($env:HOTD4_REMIX_LIVE -eq '1') { $controls.AaGuide.Text = 'MSAA applies to the original graphics. Configure ray-traced anti-aliasing in the Remix overlay. Restart the game to apply input changes.' }
    . (Join-Path $RecompDir 'raw-input-devices.ps1')
    $inputPaths = @{
        Framing = (Join-Path $RecompDir 'special-fov.txt')
        InputMode = (Join-Path $RecompDir 'input-profile.txt')
        Gun1 = (Join-Path $RecompDir 'raw-gun1.txt')
        Gun2 = (Join-Path $RecompDir 'raw-gun2.txt')
        Aspect = (Join-Path $RecompDir 'aspect-ratio.txt')
        VSync = (Join-Path $RecompDir 'vsync-profile.txt')
        AntiAliasing = (Join-Path $RecompDir 'aa-profile.txt')
        MouseSpeed = (Join-Path $RecompDir 'mouse-speed.txt')
        MouseSmoothing = (Join-Path $RecompDir 'mouse-smoothing.txt')
    }
    $inputDefaults = @{ Framing='0'; InputMode='1'; Gun1='auto'; Gun2='disabled'; AntiAliasing='4'; VSync='0'; Aspect='16:9'; MouseSpeed='1.00'; MouseSmoothing='0' }
    $inputDefaults.InputMode = if([int]$spIni.raw_mouse){'1'}else{'0'}
    $inputDefaults.AntiAliasing = [string]$spIni.aa
    $inputState = $inputDefaults.Clone()
    $choices = @{
        Framing = [ordered]@{'0'='4:3 Expanded'; '1'='5:3 Expanded'}
        InputMode = [ordered]@{'0'='Mouse (Absolute)'; '1'='Mouse (Raw Relative)'; '2'='Lightgun (Raw Input)';'3'='Co-op: Gun P1 + Mouse P2';'4'='Co-op: Gun P1 + Mouse P2 (Relative)';'5'='Keyboard (P1 + P2)'}
        MouseSpeed = [ordered]@{}
        MouseSmoothing = [ordered]@{'0'='Off'; '1'='Low'; '2'='High'}
        Aspect = [ordered]@{'16:9'='16:9'; '4:3'='4:3'}
        VSync = [ordered]@{'0'='Off'; '1'='On (sync to display)'}
        AntiAliasing = [ordered]@{'0'='Off'; '2'='MSAA 2x'; '4'='MSAA 4x'; '8'='MSAA 8x'}
    }
    foreach($speed in '0.50','0.75','1.00','1.25','1.50','2.00','2.50','3.00','4.00','5.00','6.00','8.00') {
        $choices.MouseSpeed[$speed] = "${speed}x"
    }
    $mouseIni = Join-Path $RecompDir 'lindbergh.ini'
    if ([IO.File]::Exists($mouseIni)) {
        $legacySpeed = Select-String -LiteralPath $mouseIni -Pattern '^\s*(?:mouse_sens|sensitivity)\s*=\s*([0-9]+(?:\.[0-9]+)?)' |
            Select-Object -Last 1
        if ($legacySpeed) {
            $value = [double]::Parse($legacySpeed.Matches[0].Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture)
            if ($value -ge 0.50 -and $value -le 8.00) {
                $id = $value.ToString('0.00', [Globalization.CultureInfo]::InvariantCulture)
                $inputState.MouseSpeed = $inputDefaults.MouseSpeed = $id
                if (!$choices.MouseSpeed.Contains($id)) { $choices.MouseSpeed[$id] = "${id}x" }
            }
        }
    }
    $devices = @(Get-Hotd4RawDevices)
    $inputFields = 'Framing','InputMode','Gun1','Gun2','AntiAliasing','VSync','Aspect','MouseSpeed','MouseSmoothing'
    foreach($field in $inputFields) {
        if([IO.File]::Exists($inputPaths[$field])) { $inputState[$field]=[IO.File]::ReadAllText($inputPaths[$field]).Trim() }
        if($field -in 'Gun1','Gun2') {
            $choices[$field]=[ordered]@{auto='Auto - absolute gun';disabled='Disabled'}
            foreach($device in $devices){$choices[$field][$device.Path]=$device.Name}
            if(-not $choices[$field].Contains($inputState[$field])){$choices[$field][$inputState[$field]]='Saved device (not connected)'}
        } elseif(-not $choices[$field].Contains($inputState[$field])) {
            $inputState[$field]=$inputDefaults[$field]
        }
        foreach($id in $choices[$field].Keys) {
            $item=[Windows.Controls.ComboBoxItem]::new();$item.Tag=$id;$item.Content=$choices[$field][$id]
            if($field -in 'Gun1','Gun2'){$item.ToolTip=$id}
            [void]$controls[$field].Items.Add($item)
            if($id -eq $inputState[$field]){$controls[$field].SelectedItem=$item}
        }
    }
    foreach($n in '1','2','4','8','16') {
        $i=[Windows.Controls.ComboBoxItem]::new();$i.Tag=$n;$i.Content=if($n -eq '1'){'Off'}else{"${n}x"};[void]$controls.Anisotropy.Items.Add($i)
        if([int]$n -eq [int]$spIni.af){$controls.Anisotropy.SelectedItem=$i}
    }
    foreach($n in 0,25,50,75,100) {
        $i=[Windows.Controls.ComboBoxItem]::new();$i.Tag=[string]$n;$i.Content=if($n){"$n %"}else{'Muted'};[void]$controls.Volume.Items.Add($i)
        $vol=if([int]$spIni.muted){0}else{[int]$spIni.volume};if($vol -eq $n){$controls.Volume.SelectedItem=$i}
    }
    if(!$controls.Anisotropy.SelectedItem){$controls.Anisotropy.SelectedIndex=4}
    if(!$controls.Volume.SelectedItem){$i=[Windows.Controls.ComboBoxItem]::new();$i.Tag=[string]$spIni.volume;$i.Content="$($spIni.volume) %";[void]$controls.Volume.Items.Add($i);$controls.Volume.SelectedItem=$i}
    $controls.MouseGrab.IsChecked=[int]$spIni.mouse_grab -ne 0
    $controls.LeaveReload.IsChecked=[int]$spIni.leave_reload -ne 0
    $controls.CrosshairEnabled.IsChecked=[int]$spIni.crosshair -ne 0
    $defaultInputHelp=$controls.GeneralInputHelp.Text
    $updateDeviceFields = {
        $controls.Framing.IsEnabled=$controls.Aspect.SelectedItem.Tag -ne '4:3'
        $controls.Framing.ToolTip=if(!$controls.Framing.IsEnabled){'4:3 uses the full-height original canvas.'}else{'Choose the vertical framing for widescreen output.'}
        $mode=if($controls.InputMode.SelectedItem){[string]$controls.InputMode.SelectedItem.Tag}else{'1'}
        $controls.KeyboardHelp.Visibility=if($mode -eq '5'){'Visible'}else{'Collapsed'}
        $controls.CoopGuide.Visibility=if($mode -eq '5'){'Collapsed'}else{'Visible'}
        $controls.GeneralInputHelp.Text=if($mode -eq '5'){'Use arrows for P1 and WASD for P2. P1 Shoot / Reload / Grenade: Right Ctrl / Right Shift / Right Alt. P2: Space / Q / E. Coin / Start: 5 / 1 for P1, 6 / 2 for P2. Customize all keys in Key Bindings. Restart after changing input mode.'}else{$defaultInputHelp}
        $controls.Gun1.IsEnabled=$mode -in '2','3','4';$controls.Gun2.IsEnabled=$mode -eq '2'
        $controls.Gun2.Visibility=if($mode -in '3','4','5'){'Collapsed'}else{'Visible'}
        $controls.Gun1.Visibility=$controls.Gun1Label.Visibility=$controls.Gun2Label.Visibility=if($mode -eq '5'){'Collapsed'}else{'Visible'}
        $kate=$mode -notin '3','4','5' -and $controls.SoloPlayer.SelectedItem -and $controls.SoloPlayer.SelectedItem.Tag -eq '1'
        $controls.Gun1Label.Content=if($kate){'Primary Device: Kate (P2)'}else{'Player 1 Device'}
        $controls.Gun2Label.Content=if($mode -eq '5'){'Player 2: Keyboard'}elseif($mode -in '3','4'){'Player 2: Parsec / remote mouse (automatic)'}elseif($kate){'Second Device: G (P1)'}else{'Player 2 Device'}
        $controls.SoloPlayer.IsEnabled=$mode -notin '3','4','5'
        $controls.SoloPlayerHint.Text=if($mode -in '3','4','5'){'Co-op modes use their normal P1/P2 assignments.'}else{'Your mouse or lightgun follows your character.'}
        $controls.MouseSpeed.IsEnabled=$mode -in '1','4';$controls.MouseSmoothing.IsEnabled=$mode -in '1','4'
    }
    $controls.InputMode.Add_SelectionChanged({ & $updateDeviceFields })
    $controls.Aspect.Add_SelectionChanged({ & $updateDeviceFields })
    & $updateDeviceFields

    . (Join-Path $RecompDir 'hotd4-controls.ps1')
    $bindingState=@{Data=(Read-Hotd4Controls $RecompDir);Working=$null;Capture=-1;Buttons=@{};Status='Keyboard mode uses separate P1/P2 controls below. Shared Shoot / Reload / Grenade and Service apply to mouse/gun modes. Coin / Start and system keys are common.'}
    $catalog=@(Get-Hotd4ControlCatalog)
    $refreshBindings={
        $controls.ControlSummaryList.Children.Clear()
        $summary=if($inputState.InputMode -eq '5'){@(0,1,20,21,22,23,16,17,18,19,6,7,28,29,30,31,24,25,26,27)}else{@(0..15)}
        $half=[int]($summary.Count/2);$controls.ControlSummaryList.Rows=$half
        foreach($order in 0..($half-1)){foreach($offset in 0,$half){$i=$summary[$order+$offset];$row=$catalog[$i]
            $grid=[Windows.Controls.Grid]::new();$grid.Margin=[Windows.Thickness]::new(0,3,16,3)
            $label=[Windows.Controls.TextBlock]::new();$label.Text=$row[1];$label.FontSize=14;$label.Foreground=[Windows.Media.Brushes]::LightGray
            $key=[Windows.Controls.TextBlock]::new();$key.Text=Get-Hotd4ControlSummary $bindingState.Data $i;$key.FontSize=14;$key.Foreground=[Windows.Media.BrushConverter]::new().ConvertFromString('#E9C38A');$key.HorizontalAlignment='Right'
            [void]$grid.Children.Add($label);[void]$grid.Children.Add($key);[void]$controls.ControlSummaryList.Children.Add($grid)
        }}
        foreach($i in 0..($catalog.Count-1)){if($bindingState.Working){$bindingState.Buttons[$i].Content=if($bindingState.Capture -eq $i){'Press a key...'}else{Get-Hotd4BindingName $bindingState.Working[$catalog[$i][0]]}}}
        $controls.BindingsStatus.Text=$bindingState.Status;$controls.CancelBinding.Visibility=if($bindingState.Capture -ge 0){'Visible'}else{'Collapsed'}
    }
    $assignBinding={param([int]$Value)
        $i=$bindingState.Capture;if($i -lt 0 -or !$Value){return}
        if($Value -lt 0 -and $i -notin 2,3,4,5){$bindingState.Status='Choose a keyboard key for this action.';& $refreshBindings;return}
        foreach($other in 0..($catalog.Count-1)){if($other -ne $i -and $bindingState.Working[$catalog[$other][0]] -eq $Value -and (Test-Hotd4BindingConflict $catalog[$i][0] $catalog[$other][0])){$bindingState.Status="$(Get-Hotd4BindingName $Value) is already assigned to $($catalog[$other][1]). Choose another key.";& $refreshBindings;return}}
        $bindingState.Working[$catalog[$i][0]]=$Value;$bindingState.Capture=-1;$bindingState.Status='Binding changed. Save to apply.';& $refreshBindings
    }
    foreach($group in 0,1){
        $heading=[Windows.Controls.TextBlock]::new();$heading.Text=if($group){'Keyboard Players (Keyboard input mode)'}else{'Common / Mouse / Lightgun'};$heading.FontSize=18;$heading.Foreground=[Windows.Media.Brushes]::LightGoldenrodYellow;$heading.Margin=[Windows.Thickness]::new(0,8,0,8);[void]$controls.BindingsList.Children.Add($heading)
        $groupGrid=[Windows.Controls.Primitives.UniformGrid]::new();$groupGrid.Columns=2;$groupGrid.Rows=if($group){9}else{8};[void]$controls.BindingsList.Children.Add($groupGrid)
        $indices=if($group){@(16,24,17,25,18,26,19,27,20,28,21,29,22,30,23,31,32)}else{@(0,8,1,9,2,10,3,11,4,12,5,13,6,14,7,15)}
        foreach($i in $indices){
        $grid=[Windows.Controls.Grid]::new();$grid.Margin=[Windows.Thickness]::new(0,0,16,7)
        $label=[Windows.Controls.TextBlock]::new();$label.Text=$catalog[$i][1];$label.FontSize=16;$label.VerticalAlignment='Center';$label.Margin=[Windows.Thickness]::new(12,0,0,0)
        $button=[Windows.Controls.Button]::new();$button.Width=205;$button.Height=38;$button.FontSize=15;$button.HorizontalAlignment='Right';$button.Tag=$i;$button.Margin=[Windows.Thickness]::new(0)
        [Windows.Automation.AutomationProperties]::SetName($button,"Bind $($catalog[$i][1])")
        $button.Add_Click({param($sender,$eventArgs) $bindingState.Capture=[int]$sender.Tag;$bindingState.Status=if($bindingState.Capture -eq 11){'Press a key. Escape binds Esc; Cancel Capture stops.'}else{'Press a key (Esc cancels). Mouse buttons can bind Shoot, Reload, Grenade or Fire Mode.'};& $refreshBindings})
        $bindingState.Buttons[$i]=$button;[void]$grid.Children.Add($label);[void]$grid.Children.Add($button);[void]$groupGrid.Children.Add($grid)
    }}
    $openBindings={
        $bindingState.Data=Read-Hotd4Controls $RecompDir;$bindingState.Working=[ordered]@{};foreach($row in $catalog){$bindingState.Working[$row[0]]=$bindingState.Data.Values[$row[0]]}
        $bindingState.Capture=-1;$bindingState.Status='Keyboard mode uses separate P1/P2 controls below. Shared Shoot / Reload / Grenade and Service apply to mouse/gun modes. Coin / Start and system keys are common.'
        & $refreshBindings;& $showPage 'BindingsPage'
    }
    $controls.BindingsOpen.Add_Click({& $openBindings})
    $controls.CancelBinding.Add_Click({$bindingState.Capture=-1;$bindingState.Status='Capture cancelled.';& $refreshBindings})
    $controls.ResetBindings.Add_Click({$bindingState.Capture=-1;foreach($row in $catalog){$bindingState.Working[$row[0]]=$row[2]};$bindingState.Status='Default keys restored. Save to apply.';& $refreshBindings})
    $controls.SaveBindings.Add_Click({
        try{Write-Hotd4Controls $RecompDir $bindingState.Working;$bindingState.Data=Read-Hotd4Controls $RecompDir;$bindingState.Capture=-1;$bindingState.Status='Bindings saved.';& $refreshBindings;& $showPage 'MainPage'}
        catch{$bindingState.Status=$_.Exception.Message;& $refreshBindings}
    })
    $controls.BindingsBack.Add_Click({$bindingState.Capture=-1;$bindingState.Data=Read-Hotd4Controls $RecompDir;& $refreshBindings;& $showPage 'OptionsPage'})
    $window.Add_PreviewMouseDown({param($sender,$eventArgs)
        if($bindingState.Capture -lt 0){return}
        $target=$eventArgs.OriginalSource
        while($target -and $target -isnot [Windows.Controls.Button]){try{$target=[Windows.Media.VisualTreeHelper]::GetParent($target)}catch{$target=$null}}
        if($target -eq $controls.CancelBinding){return}
        $code=switch([string]$eventArgs.ChangedButton){'Left'{-1}'Middle'{-2}'Right'{-3}'XButton1'{-4}'XButton2'{-5}default{0}}
        & $assignBinding $code;$eventArgs.Handled=$true
    })
    & $refreshBindings

    $showPage = {
        param([string] $Page)
        foreach ($name in 'MainPage','ChapterPage','OptionsPage','InputPage','GameplayPage','BindingsPage') {
            $controls[$name].Visibility = if ($name -eq $Page) { 'Visible' } else { 'Collapsed' }
        }
        $controls.ControlSummary.Visibility=if($Page -eq 'MainPage'){'Visible'}else{'Collapsed'}
            $controls.InputGuide.Visibility = if ($Page -eq 'InputPage') { 'Visible' } else { 'Collapsed' }
        $controls.CrosshairPreview.Visibility = if ($Page -eq 'OptionsPage') { 'Visible' } else { 'Collapsed' }
        switch ($Page) {

            'GameplayPage' {$controls.Hint.Text='Tab  Switch fields       Esc  Back';[void]$controls.HomeMode.Focus()}

            'BindingsPage' {$controls.Hint.Text='Esc  Back';[void]$bindingState.Buttons[0].Focus()}
            'MainPage' {
                $bindingState.Data=Read-Hotd4Controls $RecompDir;& $refreshBindings
                $controls.Hint.Text = '↑ ↓  Navigate       Enter  Select       Esc  Quit'
                [void] $controls.Arcade.Focus()
            }
            'ChapterPage' {
                $controls.ChapterHelp.Text='Special practice - '+(Get-Hotd4BindingName $bindingState.Data.Values['restart'])+' restarts the chapter'
                $controls.Hint.Text = '↑ ↓  Navigate       Enter  Start       Esc  Back'
                [void] $controls.ChapterList.Children[0].Focus()
            }
            'InputPage' {
                $controls.Hint.Text = 'Tab  Switch fields       Esc  Back'
                [void] $controls.InputMode.Focus()
            }
            'OptionsPage' {
                foreach($item in $controls.Aspect.Items){if($item.Tag -eq $inputState.Aspect){$controls.Aspect.SelectedItem=$item;break}}
                $controls.Resolution.Text = if ($state.Resolution -eq 'auto') { 'Desktop' } else { $state.Resolution }
                $controls.DisplayMode.SelectedItem = $state.DisplayMode
                foreach ($item in $controls.Hud.Items) {
                    if ($item.Tag -eq $state.Hud) { $controls.Hud.SelectedItem = $item; break }
                }
                foreach ($item in $controls.CrosshairColor.Items) {
                    if ($item.Tag -eq $state.CrosshairColor) { $controls.CrosshairColor.SelectedItem = $item; break }
                }
                foreach ($item in $controls.CrosshairSize.Items) {
                    if ($item.Tag -eq $state.CrosshairSize) { $controls.CrosshairSize.SelectedItem = $item; break }
                }
                foreach ($item in $controls.CrosshairStyle.Items) {
                    if ($item.Tag -eq $state.Crosshair) { $controls.CrosshairStyle.SelectedItem = $item; break }
                }
                foreach($item in $controls.SindenWidth.Items){if($item.Tag -eq $state.SindenWidth){$controls.SindenWidth.SelectedItem=$item;break}}
                foreach ($item in $controls.Sinden.Items) {
                    if ($item.Tag -eq $state.Sinden) { $controls.Sinden.SelectedItem = $item; break }
                }
                $controls.Hint.Text = 'Tab  Switch fields       Esc  Back'
                [void] $controls.Resolution.Focus()
            }
        }
    }

    foreach ($chapter in 1..2) {
        $button = [Windows.Controls.Button]::new()
        $button.Style = $window.FindResource('ChapterButton')
        $button.Content = "Chapter $chapter"
        $button.Tag = [string] $chapter
        $button.Add_Click( { param($sender, $eventArgs) $state.Mode = $sender.Tag; $window.Close() } )
        [void] $controls.ChapterList.Children.Add($button)
    }

    . (Join-Path $RecompDir 'hotd4-native-crosshair.ps1')
    $nativePreview=@{Ready=(Initialize-Hotd4NativeCrosshair $RecompDir '');Tick=0}
    $updateCrosshairPreview = {
        if ($null -eq $controls.CrosshairStyle.SelectedItem -or $null -eq $controls.CrosshairSize.SelectedItem -or $null -eq $controls.CrosshairColor.SelectedItem) { return }
        $style = [string] $controls.CrosshairStyle.SelectedItem.Tag
        $size = [string] $controls.CrosshairSize.SelectedItem.Tag
        $color = [string] $controls.CrosshairColor.SelectedItem.Tag
        $asset = Join-Path $RecompDir "crosshair-previews/$style-$size-$color.png"
        if($style -eq '3') {
            if(!$nativePreview.Ready){$nativePreview.Ready=Select-Hotd4NativeCrosshairSource $RecompDir $window}
            if($nativePreview.Ready){$controls.CrosshairPreviewImage.Source=[Hotd4NativeCrosshair]::Preview($RecompDir,0,[int]$nativePreview.Tick,[int]$size,[int]$color)}
            else {$controls.CrosshairPreviewImage.Source=$null}
        } elseif ([IO.File]::Exists($asset)) {
            $controls.CrosshairPreviewImage.Source = [Windows.Media.Imaging.BitmapImage]::new([uri]$asset)
        }
        $controls.CrosshairPreviewLabel.Text = "$($controls.CrosshairStyle.SelectedItem.Content) · $size % · $($controls.CrosshairColor.SelectedItem.Content)"
    }
    $nativeTimer=New-Object Windows.Threading.DispatcherTimer
    $nativeTimer.Interval=[TimeSpan]::FromMilliseconds(50)
    $nativeTimer.Add_Tick({
        if($controls.OptionsPage.IsVisible -and $controls.CrosshairStyle.SelectedItem -and $controls.CrosshairStyle.SelectedItem.Tag -eq '3' -and $nativePreview.Ready){
            $nativePreview.Tick+=3
            $controls.CrosshairPreviewImage.Source=[Hotd4NativeCrosshair]::Preview($RecompDir,0,[int]$nativePreview.Tick,[int]$controls.CrosshairSize.SelectedItem.Tag,[int]$controls.CrosshairColor.SelectedItem.Tag)
        }
    })
    $nativeTimer.Start();$window.Add_Closed({$nativeTimer.Stop()})
    $controls.CrosshairStyle.Add_SelectionChanged({ & $updateCrosshairPreview })
    $controls.CrosshairSize.Add_SelectionChanged({ & $updateCrosshairPreview })
    $controls.CrosshairColor.Add_SelectionChanged({ & $updateCrosshairPreview })
    $controls.Arcade.Add_Click( { $state.Mode = '0'; $window.Close() } )
    $controls.PlayLogged.Add_Click({$state.Mode='0';$state.LogFrames=$true;$window.Close()})
    $controls.Chapters.Add_Click( { & $showPage 'ChapterPage' } )
    $controls.Options.Add_Click( { & $showPage 'OptionsPage' } )
    $soloPath=Join-Path $RecompDir 'solo-player.txt'
    foreach($pair in @(@('0','G (P1)'),@('1','Kate (P2)'))){$entry=[Windows.Controls.ComboBoxItem]::new();$entry.Tag=$pair[0];$entry.Content=$pair[1];[void]$controls.SoloPlayer.Items.Add($entry)}
    $soloValue=if([IO.File]::Exists($soloPath) -and [IO.File]::ReadAllText($soloPath).Trim() -eq '1'){1}else{0}
    $controls.SoloPlayer.SelectedIndex=$soloValue
    $controls.SoloPlayer.Add_SelectionChanged({ & $updateDeviceFields })
    & $updateDeviceFields
    $gameplayPaths = [ordered]@{
        HomeMode = (Join-Path $RecompDir 'special-home-mode.txt')
        OffscreenReload = (Join-Path $RecompDir 'offscreen-reload.txt')
        BloodSplatter = (Join-Path $RecompDir 'blood-effects.txt')
    }
    $gameplayLabels = @{ HomeMode=@('Arcade','Home'); OffscreenReload=@('Off','On'); BloodSplatter=@('Original','Enhanced') }
    foreach($field in $gameplayPaths.Keys){
        $value=if($field -eq 'OffscreenReload'){'1'}else{'0'}
        if([IO.File]::Exists($gameplayPaths[$field])){$read=[IO.File]::ReadAllText($gameplayPaths[$field]).Trim();if($read -in '0','1'){$value=$read}}
        $labels=$gameplayLabels[$field]
        foreach($i in 0,1){$entry=[Windows.Controls.ComboBoxItem]::new();$entry.Tag=[string]$i;$entry.Content=$labels[$i];[void]$controls[$field].Items.Add($entry)}
        $controls[$field].SelectedIndex=[int]$value
    }
    $arcadeProfiles=[ordered]@{FreePlay='arcade-free-play.txt';MuteCreditSounds='arcade-mute-credit-sounds.txt'}
    $controls.GameplayOpen.Add_Click({
        foreach($name in $arcadeProfiles.Keys){
            $path=Join-Path $RecompDir $arcadeProfiles[$name]
            $controls[$name].IsChecked=[IO.File]::Exists($path) -and [IO.File]::ReadAllText($path).Trim() -eq '1'
        }
        & $showPage 'GameplayPage'
    })
    $controls.GameplayBack.Add_Click({& $showPage 'OptionsPage'})
    $controls.SaveGameplay.Add_Click({
        foreach($name in $arcadeProfiles.Keys){
            [IO.File]::WriteAllText((Join-Path $RecompDir $arcadeProfiles[$name]),[string][int][bool]$controls[$name].IsChecked)
        }
        if($controls.SoloPlayer.IsEnabled){[IO.File]::WriteAllText($soloPath,[string]$controls.SoloPlayer.SelectedItem.Tag)}
        foreach($field in $gameplayPaths.Keys){[IO.File]::WriteAllText($gameplayPaths[$field],[string]$controls[$field].SelectedItem.Tag)}
        & $showPage 'OptionsPage'
    })
    $controls.InputOptions.Add_Click({ & $showPage 'InputPage' })
    $controls.InputBack.Add_Click({ & $showPage 'OptionsPage' })
    $controls.SaveInput.Add_Click({
        foreach($field in @($inputFields | Where-Object { $_ -ne 'Aspect' })) {
            $selected = [string]$controls[$field].SelectedItem.Tag
            if ($field -in 'MouseSpeed','MouseSmoothing' -and $selected -eq $inputState[$field]) { continue }
            $inputState[$field] = $selected
            [IO.File]::WriteAllText($inputPaths[$field], $selected)
        }
        Write-Hotd4SPConfig $RecompDir @{af=[string]$controls.Anisotropy.SelectedItem.Tag;volume=[string]$controls.Volume.SelectedItem.Tag;muted=[int]([string]$controls.Volume.SelectedItem.Tag -eq '0');mouse_grab=[int][bool]$controls.MouseGrab.IsChecked;leave_reload=[int][bool]$controls.LeaveReload.IsChecked;raw_mouse=[int]($inputState.InputMode -eq '1');mouse_sens=$inputState.MouseSpeed;aa=$inputState.AntiAliasing}
        & $showPage 'OptionsPage'
    })
    $controls.Quit.Add_Click( { $window.Close() } )
    $controls.ChapterBack.Add_Click( { & $showPage 'MainPage'; [void] $controls.Chapters.Focus() } )
    $controls.OptionsBack.Add_Click( { & $updateSindenBorder; & $showPage 'MainPage'; [void] $controls.Options.Focus() } )
    $controls.Performance720p.Add_Click({
        Write-Hotd4SPConfig $RecompDir @{aa='0';af='1'}
        [IO.File]::WriteAllText($inputPaths.AntiAliasing, '0')
        [IO.File]::WriteAllText($resolutionPath, '1280x720')
        $inputState.AntiAliasing = '0'
        $controls.AntiAliasing.SelectedIndex = 0
        $controls.Anisotropy.SelectedIndex = 0
        $state.Resolution = '1280x720'
        $controls.Resolution.Text = $state.Resolution
        $controls.Hint.Text = '720p Performance saved'
    })
    $controls.SaveOptions.Add_Click( {
        $resolution = ConvertTo-Hotd4Resolution $controls.Resolution.Text
        if (!$resolution) {
            [void][Windows.MessageBox]::Show($window, 'Enter a resolution such as 2560x1440, or choose Desktop.', 'Render Resolution')
            [void]$controls.Resolution.Focus()
            return
        }
        Write-Hotd4SPConfig $RecompDir @{crosshair=[int][bool]$controls.CrosshairEnabled.IsChecked}
        $inputState.Aspect = [string]$controls.Aspect.SelectedItem.Tag
        [IO.File]::WriteAllText($inputPaths.Aspect, $inputState.Aspect)
        $state.Resolution = $resolution
        $state.DisplayMode = [string]$controls.DisplayMode.SelectedItem
        $state.Hud = [string] $controls.Hud.SelectedItem.Tag
        [IO.File]::WriteAllText($resolutionPath, $state.Resolution)
        [IO.File]::WriteAllText($displayModePath, $state.DisplayMode)
        [IO.File]::WriteAllText($hudPath, $state.Hud)
        $state.CrosshairColor = [string] $controls.CrosshairColor.SelectedItem.Tag
        [IO.File]::WriteAllText($crosshairColorPath, $state.CrosshairColor)
        $state.CrosshairSize = [string] $controls.CrosshairSize.SelectedItem.Tag
        [IO.File]::WriteAllText($crosshairSizePath, $state.CrosshairSize)
        $state.Crosshair = [string] $controls.CrosshairStyle.SelectedItem.Tag
        [IO.File]::WriteAllText($crosshairPath, $state.Crosshair)
        $state.Sinden = [string] $controls.Sinden.SelectedItem.Tag
        $state.SindenWidth=[string]$controls.SindenWidth.SelectedItem.Tag
        [IO.File]::WriteAllText($sindenWidthPath,$state.SindenWidth)
        [IO.File]::WriteAllText($sindenPath, $state.Sinden)
        & $updateSindenBorder
        & $showPage 'MainPage'
        [void] $controls.Options.Focus()
    } )
    $window.Add_ContentRendered( { & $showPage $InitialPage } )

    $window.Add_PreviewKeyDown( {
        param($sender, $eventArgs)
        if($bindingState.Capture -ge 0){
            $key=if($eventArgs.Key -eq [Windows.Input.Key]::System){$eventArgs.SystemKey}else{$eventArgs.Key}
            if($key -eq [Windows.Input.Key]::Escape -and $bindingState.Capture -ne 11){$bindingState.Capture=-1;$bindingState.Status='Capture cancelled.';& $refreshBindings}
            elseif(!$eventArgs.IsRepeat){& $assignBinding (ConvertTo-Hotd4SdlKey $key)}
            $eventArgs.Handled=$true;return
        }
        if ($eventArgs.Key -eq 'Escape') {
            if ($controls.HomeMode.IsDropDownOpen -or $controls.SoloPlayer.IsDropDownOpen -or $controls.OffscreenReload.IsDropDownOpen -or $controls.BloodSplatter.IsDropDownOpen) { return }
            if ($controls.Framing.IsDropDownOpen -or $controls.InputMode.IsDropDownOpen -or $controls.Gun1.IsDropDownOpen -or $controls.Gun2.IsDropDownOpen -or $controls.AntiAliasing.IsDropDownOpen -or $controls.VSync.IsDropDownOpen -or $controls.MouseSpeed.IsDropDownOpen -or $controls.MouseSmoothing.IsDropDownOpen) { return }
            if ($controls.Aspect.IsDropDownOpen -or $controls.Anisotropy.IsDropDownOpen -or $controls.Volume.IsDropDownOpen -or $controls.Resolution.IsDropDownOpen -or $controls.DisplayMode.IsDropDownOpen -or $controls.Hud.IsDropDownOpen -or $controls.Sinden.IsDropDownOpen -or $controls.SindenWidth.IsDropDownOpen -or $controls.CrosshairStyle.IsDropDownOpen -or $controls.CrosshairSize.IsDropDownOpen -or $controls.CrosshairColor.IsDropDownOpen) { return }
            if ($controls.MainPage.IsVisible) { $window.Close() }
            elseif ($controls.BindingsPage.IsVisible) {$controls.BindingsBack.RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))}
            elseif ($controls.GameplayPage.IsVisible) { & $showPage 'OptionsPage' }
            elseif ($controls.InputPage.IsVisible) { & $showPage 'OptionsPage' }
            elseif ($controls.OptionsPage.IsVisible) { & $showPage 'MainPage'; [void] $controls.Options.Focus() }
            else { & $showPage 'MainPage'; [void] $controls.Chapters.Focus() }
            $eventArgs.Handled = $true
        } elseif ($eventArgs.Key -in 'Up','Down' -and !$controls.OptionsPage.IsVisible -and !$controls.InputPage.IsVisible -and !$controls.GameplayPage.IsVisible -and !$controls.BindingsPage.IsVisible) {
            $direction = if ($eventArgs.Key -eq 'Up') { 'Previous' } else { 'Next' }
            $focused = [Windows.Input.Keyboard]::FocusedElement
            if ($focused -is [Windows.UIElement]) {
                $request = [Windows.Input.TraversalRequest]::new([Windows.Input.FocusNavigationDirection] $direction)
                [void] $focused.MoveFocus($request)
                $eventArgs.Handled = $true
            }
        }
    } )
    [void](Add-Hotd4GameSwitcher $window $controls.MainPage $RecompDir Special $controls.Arcade $controls.Options)
    . (Join-Path $RecompDir 'hotd-update.ps1')
    Add-HotdUpdater $window $controls.MainPage $RecompDir Special
    [void] $window.ShowDialog()
    if ($null -ne $state.Mode) { return $state }
}

