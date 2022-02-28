import Peanuts.Outlines.Outlines;
import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.Audio.AudioStatics;
import Vino.Movement.Grinding.UserGrindComponent;

event void FFidgetUsedFirstTime();

class AFidgetSpinnerActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FidgetRoot;

	UPROPERTY(DefaultComponent, Attach = FidgetRoot)
	UStaticMeshComponent FidgetBase;

	UPROPERTY(DefaultComponent, Attach = FidgetRoot)
	UStaticMeshComponent FidgetArms;

	UPROPERTY(DefaultComponent, Attach = FidgetArms)
	UNiagaraComponent SpinnerTrail01;
	default SpinnerTrail01.RelativeLocation = FVector(60.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = FidgetArms)
	UNiagaraComponent SpinnerTrail02;
	default SpinnerTrail02.RelativeLocation = FVector(-30.f, -55.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = FidgetArms)
	UNiagaraComponent SpinnerTrail03;
	default SpinnerTrail03.RelativeLocation = FVector(30.f, 55.f, 0.f);

	UPROPERTY()
	FFidgetUsedFirstTime OnFidgetUsedFirstTime;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ChargeEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent InteruptedChargeEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartSpinningEvent;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartLoopEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopLoopEvent;

	UPROPERTY()
	UStaticMesh YellowFidgetBase;

	UPROPERTY()
	UStaticMesh YellowFidgetArms;

	UPROPERTY()
	UStaticMesh BlueFidgetBase;

	UPROPERTY()
	UStaticMesh BlueFidgetArms;

	UPROPERTY(ExposeOnSpawn)
	bool bYellowFidgetspinner;

	UPROPERTY()
	UFoghornVOBankDataAssetBase VoBank;

	bool bOutlineCreated = false;

	AHazePlayerCharacter PlayerOwningFidget;

	bool bHasDied;
	bool bHasBeenUsed = false;

	bool bHasPlayerStoryBark = false;
	
	UPROPERTY(ExposeOnSpawn)
	bool bShouldPlayStoryBark = false;

	float HeightDifference = 0.f;
	float HeightLastTick = 0.f;

	FVector VeloLastTick;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FidgetBase.SetStaticMesh(bYellowFidgetspinner ? YellowFidgetBase : BlueFidgetBase);
		FidgetArms.SetStaticMesh(bYellowFidgetspinner ? YellowFidgetArms : BlueFidgetArms);
	}

	UFUNCTION()
	void StartedCharingSpinner()
	{
		PlayerOwningFidget.PlayerHazeAkComp.HazePostEvent(ChargeEvent);
	}

	UFUNCTION()
	void InteruptedCharge()
	{
		PlayerOwningFidget.PlayerHazeAkComp.HazePostEvent(InteruptedChargeEvent);
	}

	UFUNCTION()
	void FlewUpInAir()
	{
		if (PlayerOwningFidget.IsPlayerDead())
			return;

		PlayerOwningFidget.PlayerHazeAkComp.HazePostEvent(StartSpinningEvent);
		PlayerOwningFidget.PlayerHazeAkComp.HazePostEvent(StartLoopEvent);
	}

	UFUNCTION()
	void StoppedSpinning()
	{
		PlayerOwningFidget.PlayerHazeAkComp.HazePostEvent(StopLoopEvent);
	}

	UFUNCTION()
	void AudioElevationDirection(float Value)
	{
		PlayerOwningFidget.PlayerHazeAkComp.SetRTPCValue("Rtpc_Vehicles_FidgetSpinner_Elevation_Direction", Value, 0);
	}

	UFUNCTION()
	void AudioSpinFrequency(float Value)
	{
		PlayerOwningFidget.PlayerHazeAkComp.SetRTPCValue("Rtpc_Vehicles_FidgetSpinner_Spin_Frequency", Value, 0);
	}

	UFUNCTION()
	void AudioDeltaMovement(float Value)
	{
		PlayerOwningFidget.PlayerHazeAkComp.SetRTPCValue("Rtpc_Vehicles_FidgetSpinner_Velocity", Value, 0);
	}

	UFUNCTION()
	void AudioMovementSpeed(float Value)
	{
		PlayerOwningFidget.PlayerHazeAkComp.SetRTPCValue("Rtpc_Vehicles_FidgetSpinner_Velocity_Delta", Value, 0);
	}

	UFUNCTION()
	void SpinFidget(float SpinValue)
	{
		FidgetArms.AddLocalRotation(FRotator(0.f, SpinValue, 0.f) * ActorDeltaSeconds);
		float SpinFreqClamped = FMath::GetMappedRangeValueClamped(FVector2D(2000.f, 100.f), FVector2D(1.f, 0.f), SpinValue);
		AudioSpinFrequency(SpinFreqClamped);
	}

	UFUNCTION()
	void AttachToPlayer(AHazePlayerCharacter Player, bool bAttachToBack)
	{
		
		if (bAttachToBack)
		{
			FName SocketName;
			SocketName = Game::GetCody() == Player ? n"CodySpinner_Socket" : n"MaySpinner_Socket";
			AttachToActor(Player, SocketName, EAttachmentRule::SnapToTarget);
			FidgetRoot.SetRelativeRotation(FRotator::ZeroRotator);
			FidgetArms.SetRelativeRotation(FRotator::ZeroRotator);
		} else
		{
			FName SocketName;
			SocketName = Game::GetCody() == Player ? n"Align" : n"Align";
			AttachToActor(Player, SocketName, EAttachmentRule::SnapToTarget);
			FidgetRoot.SetRelativeRotation(FRotator(90.f, 0.f, 0.f));		
		}

		if (!bOutlineCreated)
		{
			bOutlineCreated = true;
			CreateMeshOutlineBasedOnPlayer(FidgetBase, Player);
			CreateMeshOutlineBasedOnPlayer(FidgetArms, Player);
		}

		PlayerOwningFidget = Player;

		if (PlayerOwningFidget == Game::GetCody())
		{
			UUserGrindComponent::Get(PlayerOwningFidget).OnGrindSplineAttached.AddUFunction(this, n"PlayerStartedGrinding");
			UUserGrindComponent::Get(PlayerOwningFidget).OnGrindSplineDetached.AddUFunction(this, n"PlayerStoppedGrinding");
		}
	}

	void CurrentVelocity(FVector Velo)
	{
		FVector Delta = Velo - VeloLastTick;

		AudioMovementSpeed(FMath::GetMappedRangeValueClamped(FVector2D(3000.f, 60.f), FVector2D(1.f, 0.f), Velo.Size()));
		AudioDeltaMovement(FMath::GetMappedRangeValueClamped(FVector2D(250.f, 50.f), FVector2D(1.f, 0.f), Delta.Size()));
		
		VeloLastTick = Velo;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (PlayerOwningFidget == nullptr)
			return;
		
		if (IsPlayerDead(PlayerOwningFidget) && !bHasDied)
			{
				bHasDied = true;
				StoppedSpinning();
				return;
			}

		if (!IsPlayerDead(PlayerOwningFidget) && bHasDied)
			bHasDied = false;

		HeightDifference = GetActorLocation().Z - HeightLastTick;
		HeightLastTick = GetActorLocation().Z;	

		HeightDifference = FMath::GetMappedRangeValueClamped(FVector2D(80.f, -30.f), FVector2D(1.f, -1.f), HeightDifference);
		AudioElevationDirection(HeightDifference);
	}

	void SpawnFakeSpinner()
	{

	}

	void FidgetUsedFirstTime()
	{
		if (!bHasBeenUsed)
		{
			bHasBeenUsed = true;
			OnFidgetUsedFirstTime.Broadcast();
		}
	}

	UFUNCTION()
	void CanPlayFidgetVO()
	{
		if (!bHasPlayerStoryBark && bShouldPlayStoryBark)
		{
			if (PlayerOwningFidget == Game::GetMay())
			{
				bHasPlayerStoryBark = true;
				PlayFoghornVOBankEvent(VoBank, n"FoghornSBPlayRoomHopscotchDungeonTreasureChest");
			}
		}
		else
		{
			FName BarkID = PlayerOwningFidget == Game::GetCody() ? n"FoghornDBPlayRoomHopscotchFidgetSpinnerEffortCody" : n"FoghornDBPlayRoomHopscotchFidgetSpinnerEffortMay";
			PlayFoghornVOBankEvent(VoBank, BarkID);
		}
	}

	UFUNCTION()
	void PlayerStartedGrinding(AGrindspline GrindSpline, EGrindAttachReason Reason)
	{
		FidgetRoot.SetRelativeRotation(FRotator(0.f, 60.f, 0.f));
	}

	UFUNCTION()
	void PlayerStoppedGrinding(AGrindspline GrindSpline, EGrindDetachReason Reason)
	{
		FidgetRoot.SetRelativeRotation(FRotator::ZeroRotator);
	}
}