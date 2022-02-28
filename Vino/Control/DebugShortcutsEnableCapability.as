
class UDebugShortcutsEnableCapability : UHazePlayerDebugInputCapability
{
	default CapabilityTags.Add(n"Debug");
	default CapabilityDebugCategory = n"Debug";

	default ActivationSequence.Add(EKeys::Gamepad_FaceButton_Top);
	default ActivationSequence.Add(EKeys::Gamepad_FaceButton_Top);
	default ActivationSequence.Add(EKeys::Gamepad_FaceButton_Bottom);
	default ActivationSequence.Add(EKeys::Gamepad_FaceButton_Bottom);
	default ActivationSequence.Add(EKeys::Gamepad_FaceButton_Left);
	default ActivationSequence.Add(EKeys::Gamepad_FaceButton_Right);
	default ActivationSequence.Add(EKeys::Gamepad_FaceButton_Left);
	default ActivationSequence.Add(EKeys::Gamepad_FaceButton_Right);

	default ActivationButton = EKeys::F8;

    UFUNCTION(BlueprintOverride)
    void OnActiveStatusChange(bool bNewStatus)
	{
		if(bNewStatus)
		{
			PrintScaled("Debug Shortcuts Enabled", Duration = 5.f, Color = FLinearColor::Green, Scale = 1.5f);
		}
		else
		{
			PrintScaled("Debug Shortcuts Disabled", Duration = 5.f, Color = FLinearColor::Red, Scale = 1.5f);
		}
	}
};