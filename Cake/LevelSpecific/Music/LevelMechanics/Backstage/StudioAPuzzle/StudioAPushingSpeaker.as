import Vino.Movement.Helpers.BurstForceStatics;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.StudioAPuzzle.StudioABlockingPlatform;

struct FSpeakerPushData
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	bool bHasBeenPushed = false;
}

class AStudioAPushingSpeaker : AStudioABlockingPlatform
{
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent BoxCollision;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UArrowComponent PushDirection;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UNiagaraComponent SoundwaveFX;
	
	TArray<FSpeakerPushData> PushDataArray;

	UPROPERTY()
	bool bDebug = false;

	bool bActive = true;

	float PushForce = 2500.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"BoxCollisionOnBeginOverlap");
		BoxCollision.OnComponentEndOverlap.AddUFunction(this, n"BoxCollisionOnEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);		
		if (bDebug)
		{
			AHazePlayerCharacter Cody = Game::GetCody();
			FVector Dir = Cody.GetActorLocation() - FVector(GetActorLocation().X, GetActorLocation().Y, Cody.GetActorLocation().Z);
			Dir.Normalize();
			Print("Dot: " + Dir.DotProduct(Cody.GetActorForwardVector()));
		}

		if (!bActive)
			return;
		
		if (PushDataArray.Num() <= 0)
			return;

		for (int i = 0; i < PushDataArray.Num(); i++)
		{
			if (!PushDataArray[i].bHasBeenPushed)
			{
				UCymbalComponent Cymbal = UCymbalComponent::Get(PushDataArray[i].Player);
				{
					if (Cymbal != nullptr)
					{
						FVector Dir = PushDataArray[i].Player.GetActorLocation() - FVector(GetActorLocation().X, GetActorLocation().Y, PushDataArray[i].Player.GetActorLocation().Z);
						Dir.Normalize();
						float CymbalDot = Dir.DotProduct(PushDataArray[i].Player.GetActorForwardVector());
						
						if (Cymbal.bShieldActive && CymbalDot < -.65f)
						{
							return;
						}
					} 
				}
				PushDataArray[i].bHasBeenPushed = true;
				PushPlayer(PushDataArray[i].Player);
			}
		}
	}

	void PushPlayer(AHazePlayerCharacter PlayerToPush)
	{
		if (PlayerToPush.HasControl())
		{
			FVector Impulse = PushDirection.ForwardVector * PushForce;
			AddBurstForce(PlayerToPush, Impulse, PlayerToPush.GetActorRotation());
		}
	}

	UFUNCTION()
	void SetSpeakerActive(bool bNewActive)
	{
		bActive = bNewActive;
		SoundwaveFX.SetHiddenInGame(!bNewActive);
	}

	UFUNCTION()
	void BoxCollisionOnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr)
			return;

		FSpeakerPushData Data;
		Data.Player = Player;

		if (PushDataArray.Contains(Data))
			return;

		FSpeakerPushData NewPushData;
		NewPushData.Player = Player;
		NewPushData.bHasBeenPushed = false;

		PushDataArray.Add(NewPushData);
	}

	UFUNCTION()
	void BoxCollisionOnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr)
			return;

		for (int i = 0; i < PushDataArray.Num(); i++)
		{
			if (PushDataArray[i].Player == Player)
				PushDataArray.RemoveAt(i);
		}
	}

	UFUNCTION()
	void StartMovingPillar(float NewStartDelay)
	{
		Super::StartMovingPillar(NewStartDelay);
		SetSpeakerActive(false);
	}
}