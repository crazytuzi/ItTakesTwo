import Cake.LevelSpecific.Music.NightClub.RythmWidget;
import Cake.LevelSpecific.Music.NightClub.RythmButtonType;

class URythmTargetWidget : URythmWidget
{
	default MovementSpeed = 0.0f;
	default DebugDrawColor = FLinearColor::Red;

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Rhythm Button Pressed"))
	void BP_OnRythmButtonPressed(ERhythmButtonType ButtonType, bool bSuccess){}
}
