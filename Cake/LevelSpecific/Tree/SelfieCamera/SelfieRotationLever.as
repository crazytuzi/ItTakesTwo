import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieStage;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfiePlayerLeverComponent;

class ASelfieRotationLever : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent ButtonBase;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent ButtonMainLeft;
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent ButtonMainRight;

	UPROPERTY(DefaultComponent, Attach = ButtonMainLeft)
	USceneComponent DistanceCheckLeft;
	UPROPERTY(DefaultComponent, Attach = ButtonMainRight)
	USceneComponent DistanceCheckRight;

	UPROPERTY(DefaultComponent)
	UBoxComponent BoxCompLeft;
	default BoxCompLeft.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxCompLeft.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent)
	UBoxComponent BoxCompRight;
	default BoxCompRight.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxCompRight.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(Category = "Setup")
	ASelfieStage Stage;

	TPerPlayer<AHazePlayerCharacter> Players;

	UPROPERTY(Category = "Setup")
	UForceFeedbackEffect SelfieCameraRumble;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ButtonOn;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ButtonOff;

	float DistanceCheck = 80.f;

	bool bLeftButtonDown;
	bool bUPROPERTYRightButtonDown;

	float StartZHeight;
	float DownZHeight;
	float DownAmount = -18.f;
	float InterpTime = 8.5f;

	FVector StartLeftLoc;
	FVector StartRightLoc;
	FVector EndLeftLoc;
	FVector EndRightLoc;

	bool bCanActivateLeft;
	bool bCanActivateRight;

	bool bLeftDown;
	bool bRightDown;

	int LeftPlayerCount;
	int RightPlayerCount;

	float LeftTimer;
	float RightTimer;
	float StartTimer = 0.2f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLeftLoc = ButtonMainLeft.WorldLocation;
		StartRightLoc = ButtonMainRight.WorldLocation;
		EndLeftLoc += StartLeftLoc + FVector(0.f, 0.f, DownAmount);
		EndRightLoc += StartRightLoc + FVector(0.f, 0.f, DownAmount);

		BoxCompLeft.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlapLeft");
		BoxCompLeft.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlapLeft");
		BoxCompRight.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlapRight");
		BoxCompRight.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlapRight");
		
		if (!HasControl())
			return;
			
		bCanActivateLeft = true;
		bCanActivateRight = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bLeftDown)
			ButtonMainLeft.SetWorldLocation(FMath::VInterpTo(ButtonMainLeft.GetWorldLocation(), EndLeftLoc, DeltaTime, InterpTime)); 
		else
			ButtonMainLeft.SetWorldLocation(FMath::VInterpTo(ButtonMainLeft.GetWorldLocation(), StartLeftLoc, DeltaTime, InterpTime)); 

		if (bRightDown)
			ButtonMainRight.SetWorldLocation(FMath::VInterpTo(ButtonMainRight.GetWorldLocation(), EndRightLoc, DeltaTime, InterpTime)); 
		else
			ButtonMainRight.SetWorldLocation(FMath::VInterpTo(ButtonMainRight.GetWorldLocation(), StartRightLoc, DeltaTime, InterpTime)); 

		if (HasControl())
		{
			float DistanceLeftMay = (Game::May.ActorLocation -  DistanceCheckLeft.WorldLocation).Size();
			float DistanceLeftCody = (Game::Cody.ActorLocation -  DistanceCheckLeft.WorldLocation).Size();
			float DistanceRightMay = (Game::May.ActorLocation -  DistanceCheckRight.WorldLocation).Size();
			float DistanceRightCody = (Game::Cody.ActorLocation -  DistanceCheckRight.WorldLocation).Size();

			if (LeftPlayerCount > 0)
			{
				if (LeftTimer > 0.f)
					LeftTimer -= DeltaTime;
				else
					TurnStageLeft();
			}
			else
			{
				if (!bCanActivateLeft)
					bCanActivateLeft = true;
			}

			if (RightPlayerCount > 0)
			{
				if (RightTimer > 0.f)
					RightTimer -= DeltaTime;
				else
					TurnStageRight();
			}
			else
			{
				if (!bCanActivateRight)
					bCanActivateRight = true;
			}
		}
	}

	//NOTE: Left and Right need to be reversed on stage as the stage's perspective is facing towards the player
	UFUNCTION()
	void TurnStageLeft()
	{
		if (bCanActivateLeft)
		{
			bCanActivateLeft = false;
			Stage.NetActivateStageRotation(EStageDirection::Right);
			
			for(AHazePlayerCharacter CurrentPlayer : Players)
			{
				if (CurrentPlayer != nullptr)
					CurrentPlayer.PlayForceFeedback(SelfieCameraRumble, false, true, n"StageRumble");
			}		
		}
	}

	UFUNCTION()
	void TurnStageRight()
	{
		if (bCanActivateRight)
		{
			bCanActivateRight = false;
			Stage.NetActivateStageRotation(EStageDirection::Left);

			for(AHazePlayerCharacter CurrentPlayer : Players)
			{
				if (CurrentPlayer != nullptr)
					CurrentPlayer.PlayForceFeedback(SelfieCameraRumble, false, true, n"StageRumble");
			}
		}
	}

	UFUNCTION()
	void LeftButtonState(bool Value)
	{
		if (!bLeftDown && Value)
			LeftTimer = StartTimer;

		bLeftDown = Value;
	}

	UFUNCTION()
	void RightButtonState(bool Value)
	{
		if (!bRightDown && Value)
			RightTimer = StartTimer;

		bRightDown = Value;
	}

	UFUNCTION()
    void TriggeredOnBeginOverlapLeft(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (Player != nullptr)
			Players[Player] = Player;

		if (LeftPlayerCount == 0)
		{
			UHazeAkComponent::HazePostEventFireForget(ButtonOn, FTransform(ButtonMainLeft.GetWorldLocation()));
		}

		LeftPlayerCount++;
		LeftButtonState(true);
    }

	UFUNCTION()
    void TriggeredOnBeginOverlapRight(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (Player != nullptr)
			Players[Player] = Player;
		
		if (RightPlayerCount == 0)
		{
			UHazeAkComponent::HazePostEventFireForget(ButtonOn, FTransform(ButtonMainRight.GetWorldLocation()));
		}
		
		RightPlayerCount++;
		RightButtonState(true);
    }

	UFUNCTION()
    void TriggeredOnEndOverlapLeft(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (Player != nullptr)
			Players[Player] = nullptr;

		LeftPlayerCount--;

		if (LeftPlayerCount == 0)
		{
			UHazeAkComponent::HazePostEventFireForget(ButtonOff, FTransform(ButtonMainLeft.GetWorldLocation()));
			LeftButtonState(false);
		}
    }

	UFUNCTION()
    void TriggeredOnEndOverlapRight(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (Player != nullptr)
			Players[Player] = nullptr;

		RightPlayerCount--;

		if (RightPlayerCount == 0)
		{
			UHazeAkComponent::HazePostEventFireForget(ButtonOff, FTransform(ButtonMainRight.GetWorldLocation()));
			RightButtonState(false);
		}
    }
}