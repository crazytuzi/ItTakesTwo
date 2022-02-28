import Rice.OptionsMenu.OptionsMenuTab;
import Rice.Settings.GameSettingsRadioOptionsAudioGroup;

class UAudioOptionsTabWidget : UOptionsTabWidget
{
	private UGameSettingsRadioOptionsAudioGroup RadioOptionsGroup;

	UFUNCTION(BlueprintEvent)
	TArray<UGameSettingsRadioOptionWidget> GetRadioOptions() { return TArray<UGameSettingsRadioOptionWidget>(); }

	UFUNCTION(BlueprintOverride)
	void OnInitialized()
	{
		RadioOptionsGroup = UGameSettingsRadioOptionsAudioGroup();
		RadioOptionsGroup.SetWidgets(GetRadioOptions());
	}
}