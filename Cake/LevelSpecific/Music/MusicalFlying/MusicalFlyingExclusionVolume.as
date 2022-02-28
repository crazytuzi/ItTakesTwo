import Cake.LevelSpecific.Music.MusicalFlying.MusicFlyingVolumeBase;

import void OnFlyingExclusionVolumeEnter(AActor, AMusicalFlyingExclusionVolume, UPrimitiveComponent) from "Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent";
import void OnFlyingExclusionVolumeExit(AActor, AMusicalFlyingExclusionVolume, UPrimitiveComponent) from "Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent";

class AMusicalFlyingExclusionVolume : AMusicFlyingVolumeBase
{	
	default Shape::SetVolumeBrushColor(this, FLinearColor(0.f, 0.25f, 1.f, 1.f));

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActivateFlyingVolume();
	}

	UFUNCTION()
	void BrushBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, const FHitResult&in Hit) override
	{
#if !RELEASE
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(!devEnsure(Player != nullptr, "This object should only register overlaps from the player."))
			return;
#endif // !RELEASE
		OnFlyingExclusionVolumeEnter(OtherActor, this, OverlappedComponent);
	}

	UFUNCTION()
    void BrushEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex) override
	{
#if !RELEASE
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(!devEnsure(Player != nullptr, "This object should only register overlaps from the player."))
			return;
#endif // !RELEASE
		OnFlyingExclusionVolumeExit(OtherActor, this, OverlappedComponent);
	}
}