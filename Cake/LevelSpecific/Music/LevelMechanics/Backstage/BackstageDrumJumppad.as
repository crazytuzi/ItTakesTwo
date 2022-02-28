import Cake.LevelSpecific.Music.MusicJumpTo.MusicJumpToStatics;
class ABackstageDrumJumppad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent JumpToLocation;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UBoxComponent BoxCollision;

	UPROPERTY()
	ABackstageDrumJumppad NextDrumToJumpTo;

	UPROPERTY()
	AActor LocationToLand;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BounceAudioEvent;

	UPROPERTY()
	float AdditionalHeight = 1500.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{		
		BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnBoxCollisionOverlap");
	}

	UFUNCTION()
	void OnBoxCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr)
			return;

		Player.PlayerHazeAkComp.HazePostEvent(BounceAudioEvent);

		if (NextDrumToJumpTo != nullptr)
		{	

			FHazeJumpToData JumpData;
			JumpData.Transform = NextDrumToJumpTo.JumpToLocation.WorldTransform;
			JumpData.AdditionalHeight = AdditionalHeight;
			MusicJumpTo::ActivateMusicJumpTo(Player, JumpData);
			return;
		}

		if (LocationToLand != nullptr)
		{
			FHazeJumpToData JumpData;
			JumpData.Transform = LocationToLand.ActorTransform;
			JumpData.AdditionalHeight = AdditionalHeight;
			MusicJumpTo::ActivateMusicJumpTo(Player, JumpData);
			return;
		}
	}
}