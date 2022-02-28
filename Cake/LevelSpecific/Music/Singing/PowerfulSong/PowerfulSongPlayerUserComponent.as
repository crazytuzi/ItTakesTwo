import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongAbstractUserComponent;
import Cake.LevelSpecific.Music.Singing.SingingSettings;

UCLASS(hidecategories = "Settings")
class UPowerfulSongPlayerUserComponent : UPowerfulSongAbstractUserComponent
{
	USingingSettings SingingSettings;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SingingSettings = USingingSettings::GetSettings(Player);
	}

	protected float GetHorizontalOffsetValue() const property { return SingingSettings.HorizontalOffset; }
	protected float GetVerticalOffsetValue() const property { return SingingSettings.VerticalOffset; }
	protected float GetHorizontalAngleValue() const property { return SingingSettings.HorizontalAngle; }
	protected float GetVerticalAngleValue() const property { return SingingSettings.VerticalAngle; }

	FVector GetPowerfulSongForward() const property { return Player.ViewRotation.GetForwardVector(); }
	FVector GetPowerfulSongStartLocation() const property { return Player.Mesh.GetSocketLocation(n"Head"); }

	float GetPowerfulSongRange() const property { return SingingSettings.SingingRange; }

	FVector GetPowerfulSongRightVector() const property
	{
		return Player.ViewRotation.RightVector;
	}
}
