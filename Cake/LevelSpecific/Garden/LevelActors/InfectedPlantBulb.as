import Peanuts.ButtonMash.Progress.ButtonMashProgress;

event void FOnCleanseStarted();
event void FOnCleansing(float SequenceTime);
event void FOnCleanseStopped();
event void FOnCleanseSuccessful();

UCLASS(Abstract)
class AInfectedPlantBulb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BulbRoot;

	UPROPERTY(DefaultComponent, Attach = BulbRoot)
	UStaticMeshComponent BulbMesh;

	UPROPERTY(DefaultComponent, Attach = BulbRoot)
	USceneComponent ButtonMashAttachment;

	UPROPERTY(DefaultComponent, Attach = BulbRoot)
	USphereComponent Trigger;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CleanseAnim;

	UPROPERTY()
	FOnCleanseStarted OnCleanseStarted;

	UPROPERTY()
	FOnCleansing OnCleansing;

	UPROPERTY()
	FOnCleanseStopped OnCleanseStopped;

	UPROPERTY()
	FOnCleanseSuccessful OnCleanseSuccessful;

	bool bCleansing = false;
	bool bFullyCleansed = false;

	AHazePlayerCharacter CleansingPlayer;

	UButtonMashProgressHandle ButtonMashHandle;

	float DecayRate = 0.35f;
	float IconHorizontalOffset = 400.f;
	float IconVerticalOffset = 200.f;
	float PlayerOffset = 500.f;
	FVector DirToPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
		Trigger.OnComponentEndOverlap.AddUFunction(this, n"ExitTrigger");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bFullyCleansed)
			return;

		if (ButtonMashHandle != nullptr)
		{
			float NewProgress = ButtonMashHandle.Progress + ButtonMashHandle.MashRateControlSide * 0.1f * DeltaTime;
			NewProgress -= DecayRate * DeltaTime;
			ButtonMashHandle.Progress = NewProgress;

			if (ButtonMashHandle.MashRateControlSide > 0.f)
			{
				if (bCleansing)
				{
					float CurSequenceTime = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(0.f, 0.63f), ButtonMashHandle.Progress);
					OnCleansing.Broadcast(CurSequenceTime);
				}

				StartCleansing();
			}
			else
			{
				StopCleansing();
			}

			if (ButtonMashHandle.Progress >= 1.f)
			{
				FullyCleanse();
			}
		}

		DirToPlayer = Game::GetCody().ActorLocation - ActorLocation;
		DirToPlayer = Math::ConstrainVectorToPlane(DirToPlayer, FVector::UpVector);
		DirToPlayer.Normalize();

		FVector AttachmentLoc = ActorLocation + (DirToPlayer * IconHorizontalOffset) + FVector(0.f, 0.f, IconVerticalOffset);
		ButtonMashAttachment.SetWorldLocation(AttachmentLoc);
	}

	void StartCleansing()
	{
		if (!bCleansing)
		{
			bCleansing = true;
			CleansingPlayer.BlockCapabilities(CapabilityTags::Movement, this);

			FVector Dir = -DirToPlayer;
			CleansingPlayer.SmoothSetLocationAndRotation(ActorLocation + (DirToPlayer * PlayerOffset), Dir.Rotation());

			OnCleanseStarted.Broadcast();
		}
	}

	void StopCleansing()
	{
		if (bCleansing)
		{
			bCleansing = false;
			CleansingPlayer.StopAnimation();
			CleansingPlayer.UnblockCapabilities(CapabilityTags::Movement, this);

			OnCleanseStopped.Broadcast();
		}
	}

	void FullyCleanse()
	{
		OnCleanseSuccessful.Broadcast();
		bFullyCleansed = true;
		StopCleansing();
		ButtonMashHandle.StopButtonMash();
		BP_FullyCleansed();
	}

	UFUNCTION(BlueprintEvent)
	void BP_FullyCleansed()
	{

	}

	UFUNCTION(NotBlueprintCallable)
	void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if (bFullyCleansed)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr && Player == Game::GetCody())
		{
			CleansingPlayer = Player;
			ButtonMashHandle = StartButtonMashProgressAttachToComponent(Player, ButtonMashAttachment, NAME_None, FVector::ZeroVector);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void ExitTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		if (bFullyCleansed)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr && Player == Game::GetCody() && ButtonMashHandle != nullptr)
		{
			ButtonMashHandle.StopButtonMash();
			ButtonMashHandle = nullptr;
			CleansingPlayer = nullptr;
		}
	}
}