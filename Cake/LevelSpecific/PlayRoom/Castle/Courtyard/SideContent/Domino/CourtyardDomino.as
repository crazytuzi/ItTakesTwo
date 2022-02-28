import Cake.LevelSpecific.PlayRoom.VOBanks.CastleCourtyardVOBank;

class ACourtyardDomino : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent DominoMesh;

	UPROPERTY(DefaultComponent)
	USceneComponent ImpulseLocation;

	UPROPERTY(DefaultComponent)
	UBoxComponent PlayerCollider;

	UPROPERTY()
	UCastleCourtyardVOBank VOBank;

	UPROPERTY()
	UAkAudioEvent DominoHitEvent;
	
	bool bPushed = false;
	bool bHasPlayedSound = false;

	AHazePlayerCharacter PushPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerCollider.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		DominoMesh.OnComponentHit.AddUFunction(this, n"OnComponentHit");
	}

	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		UPrimitiveComponent OtherComponent, int OtherBodyIndex,
		bool bFromSweep, FHitResult& Hit)
	{

		if (bPushed)
			return;
		
		if(!bHasPlayedSound)
		{
			UHazeAkComponent::HazePostEventFireForget(DominoHitEvent, FTransform(ImpulseLocation.WorldLocation));
			bHasPlayedSound = true;
		}

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;			

		FVector ToPlayer = Player.ActorLocation - ActorLocation;
		FVector Force = ActorRightVector * FMath::Sign(ToPlayer.DotProduct(-ActorRightVector)) * 20000.f;

		NetPushDomino(Force, Player);
	}
	
	UFUNCTION()
	void OnComponentHit(UPrimitiveComponent HitComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, FVector NormalImpulse, FHitResult& Hit)
	{
		if (bPushed)
			return;

		ACourtyardDomino OtherDomino = Cast<ACourtyardDomino>(OtherActor);
		if (OtherDomino == nullptr)
			return;		

		bPushed = true;
	}

	UFUNCTION(NetFunction)
	void NetPushDomino(FVector Force, AHazePlayerCharacter Player)
	{
		if (bPushed)
			return;

		DominoMesh.AddImpulseAtLocation(Force, ImpulseLocation.WorldLocation);
		PushPlayer = Player;

		bPushed = true;

		if (Force.DotProduct(ActorRightVector) > 0.f)
		{
			FName EventName = Player.IsMay() ? n"FoghornDBPlayroomCastleDominoes_May" : n"FoghornDBPlayroomCastleDominoes_Cody";
			PlayFoghornVOBankEvent(VOBank, EventName);
		}
	}
}