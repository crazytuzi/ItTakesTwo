class UCameraSettingsComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UHazeCameraSettingsComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UHazeCameraSettingsComponent SettingsComp = Cast<UHazeCameraSettingsComponent>(Component);
        if (!ensure((SettingsComp != nullptr) && (SettingsComp.GetOwner() != nullptr)))
            return;
        
		if (SettingsComp.Camera != nullptr)
		{
			FLinearColor Color = FLinearColor::Black;
			switch(SettingsComp.Player)
			{
				case EHazeSelectPlayer::Both:
					Color = FLinearColor::Yellow;
					break;
				case EHazeSelectPlayer::May:
					Color = AHazePlayerCharacter::GetPlayerDebugColor(EHazePlayer::May); 
					break;
				case EHazeSelectPlayer::Cody:
					Color = AHazePlayerCharacter::GetPlayerDebugColor(EHazePlayer::Cody); 
					break;
			}
			DrawDashedLine(SettingsComp.GetOwner().GetActorLocation(), SettingsComp.Camera.GetActorLocation(), Color, 20);
		}
    }   
} 

