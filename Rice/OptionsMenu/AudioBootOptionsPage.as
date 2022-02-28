import Rice.Settings.GameSettingsRadioOptionsAudioGroup;
import Rice.OptionsMenu.BootOptionsPage;

class UAudioBootOptionsPage : UBootOptionsPage
{
	private UGameSettingsRadioOptionsAudioGroup RadioOptionsGroup;

	UFUNCTION(BlueprintEvent)
	TArray<UGameSettingsRadioOptionWidget> GetRadioOptions() { return TArray<UGameSettingsRadioOptionWidget>(); }

	UFUNCTION(BlueprintOverride)
	void OnInitialized()
	{
		RadioOptionsGroup = UGameSettingsRadioOptionsAudioGroup();
		RadioOptionsGroup.SetWidgets(GetRadioOptions());

		GetAudioManager().SetBootConfigurationSettings();
	}
}