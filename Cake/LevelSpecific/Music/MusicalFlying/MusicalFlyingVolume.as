import Cake.LevelSpecific.Music.MusicalFlying.MusicFlyingVolumeBase;

import void OnFlyingVolumeEnter(AActor, AMusicalFlyingVolume) from "Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent";
import void OnFlyingVolumeExit(AActor, AMusicalFlyingVolume, UPrimitiveComponent) from "Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent";

UCLASS(HideCategories = "Cooking Replication Collision Debug Actor Tags HLOD Mobile AssetUserData Input LOD Rendering")
class AMusicalFlyingVolume : AMusicFlyingVolumeBase
{				
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		if(bStartActive)
		{
			ActivateFlyingVolume();
		// Hack for when player spawns within a volume, such as in test levels.
		#if EDITOR
			System::SetTimer(this, n"StartupHack", 0.5f, false);
		#endif // EDITOR
		}
	}

#if EDITOR
	UFUNCTION()
	void StartupHack()
	{
		TArray<UPrimitiveComponent> OverlappingComps;
		GetOverlappingComponents(OverlappingComps);
		for (UPrimitiveComponent Overlap : OverlappingComps)
		{
			if ((Overlap != nullptr) && (Overlap.GetOwner() != nullptr))
				BrushBeginOverlap(BrushComponent, Overlap.GetOwner(), Overlap, -1, false, FHitResult());
		}
	}
#endif // EDITOR

	UFUNCTION()
	void BrushBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, const FHitResult&in Hit) override
	{
#if !RELEASE
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(!devEnsure(Player != nullptr, "This object should only register overlaps from the player."))
			return;
#endif // !RELEASE
		OnFlyingVolumeEnter(OtherActor, this);
	}

	UFUNCTION()
    void BrushEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex) override
	{
#if !RELEASE
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(!devEnsure(Player != nullptr, "This object should only register overlaps from the player."))
			return;
#endif // !RELEASE
		OnFlyingVolumeExit(OtherActor, this, OverlappedComponent);
	}
}
