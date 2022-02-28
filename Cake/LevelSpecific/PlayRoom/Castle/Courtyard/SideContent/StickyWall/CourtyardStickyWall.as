import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureStickyWall;
import Cake.LevelSpecific.PlayRoom.VOBanks.CastleCourtyardVOBank;
class ACourtyardStickyWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayStruggleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopStruggleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayEffortMayAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopEffortMayAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayEffortCodyAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopEffortCodyAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UCastleCourtyardVOBank VOBank;

	UPROPERTY(DefaultComponent)
	UBoxComponent Box;
	default Box.SetCollisionProfileName(n"OverlapAllDynamic");

	UPROPERTY()
	UHazeCapabilitySheet PlayerSheet;

	UPROPERTY()
	TPerPlayer<ULocomotionFeatureStickyWall> PlayerFeatures;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Capability::AddPlayerCapabilitySheetRequest(PlayerSheet);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Capability::RemovePlayerCapabilitySheetRequest(PlayerSheet);
	}
}