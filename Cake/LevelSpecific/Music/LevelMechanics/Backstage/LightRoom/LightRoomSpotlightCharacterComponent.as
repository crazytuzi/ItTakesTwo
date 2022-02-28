import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomSpotlight;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomSpotlightController;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomSpotlightSafeZone;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomDeathLightActor;


UFUNCTION()
void InitializeLightRoomSpotlight(AHazePlayerCharacter TargetPlayer, ALightRoomSpotlight NewSpotlight, ALightRoomSpotlightController NewSpotlightController)
{
	ULightRoomSpotlightCharacterComponent Comp = ULightRoomSpotlightCharacterComponent::Get(TargetPlayer);

	if (Comp != nullptr)
	{
		Comp.Spotlight = NewSpotlight;
		Comp.SpotlightController = NewSpotlightController;
	}
}

UFUNCTION()
void EnableLightRoomDeathCapability(AHazePlayerCharacter TargetPlayer, bool bEnable)
{
	ULightRoomSpotlightCharacterComponent Comp = ULightRoomSpotlightCharacterComponent::Get(TargetPlayer);

	if (Comp != nullptr)
	{
		Comp.bLightRoomDeathEnabled = bEnable;

		if (bEnable)
		{
			GetAllActorsOfClass(Comp.SpotlightLocationActors);
			GetAllActorsOfClass(Comp.SafeZones);

			TArray<ALightRoomDeathLightActor> TempArray;
			GetAllActorsOfClass(TempArray);
			Comp.DeathLightActor = TempArray[0];
			Comp.DeathLightActor.AttachToActor(TargetPlayer, n"", EAttachmentRule::SnapToTarget);
			TargetPlayer.ApplySettings(Comp.HealthSettings, Comp);
		}
	}
}

class ULightRoomSpotlightCharacterComponent : UActorComponent
{
	ALightRoomSpotlight Spotlight;
	ALightRoomSpotlightController SpotlightController;

	bool bLightRoomDeathEnabled = false;
	TArray<ALightRoomSpotlightLocationActor> SpotlightLocationActors;
	TArray<ALightRoomSpotlightSafeZone> SafeZones;
	
	UPROPERTY()
	UForceFeedbackEffect DeathForceFeedback;

	UPROPERTY()
	ALightRoomDeathLightActor DeathLightActor;

	UPROPERTY()
	UPlayerHealthSettings HealthSettings;

	UPROPERTY()
	TSubclassOf<UPlayerDamageEffect> DamageEffect;

	UPROPERTY()
	UFoghornVOBankDataAssetBase FoghornDataAsset;
	

	// Change ControlSide on all associated spotlight actors.
	void ChangeControlSide(UObject NewControlSide)
	{
		Spotlight.ChangeControlSide(NewControlSide);
	}
}