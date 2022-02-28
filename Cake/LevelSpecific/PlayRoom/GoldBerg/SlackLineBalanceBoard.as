import Peanuts.Spline.SplineActor;
import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.MarbleBall.MarbleBall;
import Cake.LevelSpecific.PlayRoom.GoldBerg.MarbleTags;
import Cake.LevelSpecific.PlayRoom.GoldBerg.SlacklineMonowheelAnimationDataComponent;
import Peanuts.Audio.AudioStatics;

event void FBallFelloutOfBoard(bool FellForward, bool BallFellOut);
event void FBallIsOnBoard();
event void FBalanceBoardPlayerEvent(AHazePlayerCharacter Player);
event void FBalanceBoardSuccessEvent();

UCLASS(abstract)
class ASlackLineBalanceBoard : AStaticMeshActor
{
	UPROPERTY()
	AHazePlayerCharacter OwningPlayer;

	float CurrentBalanceInput;
	
	FBallFelloutOfBoard OnBallFellOutOfBoard; 
	FBallIsOnBoard OnBallIsOnBoard;

	UPROPERTY(Category = "SlacklineWheel")
	FBalanceBoardPlayerEvent CloseToFailBalanceboard;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartBalanceBoardAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopBalanceBoardAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BoardImpactAudioEvent;
	
	UPROPERTY()
	USlacklineMonoWheelAnimationDataComponent AnimationDataComponent;

	UPROPERTY()
	AHazeActor BalanceBoardBall;

	UPROPERTY()
	FBalanceBoardSuccessEvent OnSuccess;

	UPROPERTY()
	UHazeCameraSettingsDataAsset TensionCameraSettings;

	UPROPERTY()
	UHazeCameraSettingsDataAsset BalanceboardCameraSettings;
	
	UPROPERTY(DefaultComponent, Attach = Base)
	USceneComponent BallResetSpawnposition;

	UPROPERTY(Attach = Base, DefaultComponent)
	UBoxComponent BallTrigger;

	UPROPERTY(Attach = Base, DefaultComponent)
	UHazeSplineComponent BallSpline;

	UPROPERTY(Attach = Base, DefaultComponent)
	USceneComponent BallTarget;

	UPROPERTY(Attach = Base, DefaultComponent)
	USceneComponent BalanceBoardMiddleposition;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent BalanceSync;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent VelocitySync;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent BallPositionSync;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	AHazeActor FailMarble;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> TensionCameraShake;

	UPROPERTY()
	UForceFeedbackEffect TensionRumble;

	UPROPERTY()
	TSubclassOf<AHazeActor> ActorToSpawn;

	bool IsRunningFailstate = false;
	bool HasBroadCastedFailstate = false;
	bool ReleasedBall = false;
	bool ReachedEnd = false;
	bool bBoardHit = false;
	bool bBlockBallRoll = false;

	AMarbleBall Marble;

	float RollAlpha = 0;
	float MaxRoll = 10;

	float RollVelocity = 0;
	float RandomRollVelocity = 0;

	float RandomDesiredInput = 0;
	float TimeSinceUpdatedRandomInput = 0;

	float BallVelocity;
	float MaxBallAcceleration = 6;

	FVector BallTargetLocalStartPosition;
	
	UPROPERTY()
	TSubclassOf<UHazeCapability> RequiredCapabilityType;

	void SetPlayerOwner(AHazePlayerCharacter Player) property
	{
		OwningPlayer = Player;
		BalanceSync.OverrideControlSide(Player);
		BallPositionSync.OverrideControlSide(Player);
		VelocitySync.OverrideControlSide(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
        BallTrigger.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
		BallTargetLocalStartPosition = BallTarget.RelativeLocation;
		Capability::AddPlayerCapabilityRequest(RequiredCapabilityType);
		HazeAkComp.HazePostEvent(StartBalanceBoardAudioEvent);
	}

    UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(RequiredCapabilityType);
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)

    {
		if(Marble != nullptr)
			return;

		if (OverlappedComponent == BallTrigger)
		{
			AMarbleBall Marbleball = Cast<AMarbleBall>(OtherActor);

			if (Marbleball != nullptr)
			{
				Marbleball.Spline = nullptr;
				BalanceBoardBall = Marbleball;
				BalanceBoardBall.SetCapabilityAttributeObject(FMarbleTags::LockedOnBalanceboardComponent, BallTarget);
				OnBallIsOnBoard.Broadcast();
				Marble = Marbleball;
			}
		}
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (OwningPlayer != nullptr && ReleasedBall == false)
		{
			CalcRollAlpha(DeltaTime);
			SetBallLocation(DeltaTime);
			CalcBallOffsetFromCenter();
			HazeAkComp.SetRTPCValue("Rtpc_Vehicles_MonoWheelBike_Tilting_Side", BalanceSync.Value);

			CheckCameraTensionSettings();
		}

		if (!bBoardHit)
		{
			if (ReachedEnd && RollAlpha == -1)
			{
				OwningPlayer.PlayerHazeAkComp.HazePostEvent(BoardImpactAudioEvent);
				bBoardHit = true;
			}
			if (ReachedEnd && RollAlpha != -1)
			{
				bBoardHit = false;
			}
		}
	}

	void CheckCameraTensionSettings()
	{
		if (IsInTensionMode && ReleasedBall == false)
		{
			FHazeCameraBlendSettings BlendSettings;
			BlendSettings.BlendTime = 1;

			OwningPlayer.PlayCameraShake(TensionCameraShake, 1);
			OwningPlayer.PlayForceFeedback(TensionRumble, true, true, n"SlacklineBalanceBoard");
			CloseToFailBalanceboard.Broadcast(OwningPlayer);
			OwningPlayer.ApplyCameraSettings(TensionCameraSettings, BlendSettings, BallTarget, EHazeCameraPriority::High);
		}
		else
		{
			OwningPlayer.StopAllCameraShakes();
			OwningPlayer.StopForceFeedback(TensionRumble, n"SlacklineBalanceBoard");
			OwningPlayer.ClearCameraSettingsByInstigator(BallTarget);

			FHazeCameraBlendSettings BlendSettings;
			BlendSettings.BlendTime = 0.5f;
			FHazeCameraClampSettings Clampsettings;
			FHazeCameraSpringArmSettings SpringarmSettings;
		}
	}

	float GetDotToCenter() property
	{
		FVector DirToBall = Marble.GetActorLocation() - BalanceBoardMiddleposition.WorldLocation;
		DirToBall = DirToBall.GetSafeNormal();
		float DotToRight = DirToBall.DotProduct(ActorRightVector);

		return DotToRight;
	}

	float GetDistanceToMiddle() property
	{
		return BallTarget.WorldLocation.Distance(BalanceBoardMiddleposition.WorldLocation);
	}

	void CalcBallOffsetFromCenter()
	{
		if(DistanceToMiddle > 180)
		{
			if(OwningPlayer.HasControl())
			{
				if (DotToCenter > 0 && ReachedEnd && !IsRunningFailstate)
				{
					OnSuccess.Broadcast();
					return;
				}
				
				else if (!IsRunningFailstate)
				{
					if (!HasBroadCastedFailstate)
					{
						TriggerFailstate();
					}
				}
			}
		}
	}

	UFUNCTION()
	AMarbleBall GetMarbleBall()
	{
		return Marble;
	}

	UFUNCTION()
	void TriggerFailstate()
	{
		ReleaseMarbleBall();
		HasBroadCastedFailstate = true;
		OnBallFellOutOfBoard.Broadcast(false, false);
	}

	UFUNCTION(BlueprintPure)
	float GetMarbleVelocity()
	{
		return BallVelocity;
	}

	void SetBallLocation(float DeltaTime)
	{
		if (OwningPlayer.HasControl())
		{
			BallVelocity -= RollAlpha * MaxBallAcceleration * DeltaTime;
			BallVelocity *= FMath::Pow(0.5f, DeltaTime);
			FVector Deltavelocity = FVector::RightVector;
			Deltavelocity *= BallVelocity;
			BallTarget.AddRelativeLocation(Deltavelocity);
			BallPositionSync.Value = BallTarget.RelativeLocation;
			VelocitySync.Value = BallVelocity;
		}
		else
		{
			BallTarget.SetRelativeLocation(BallPositionSync.Value);
			BalanceBoardBall.SetActorLocation(BallTarget.WorldLocation);
			BallVelocity = VelocitySync.Value;
		}
	}

	bool GetIsInTensionMode() property
	{
		return DistanceToMiddle > 75.f;
	}

	UFUNCTION()
	void ReleaseMarbleBall()
	{
		ReleasedBall = true;
		Marble.SetCapabilityAttributeObject(FMarbleTags::LockedOnBalanceboardComponent, nullptr);
		ClearCameraSettings();
	}

	UFUNCTION()
	void ResetBalanceboard()
	{
		BalanceBoardBall.SetCapabilityAttributeObject(FMarbleTags::LockedOnBalanceboardComponent, BallTarget);
		BallVelocity = 0;
		BallTarget.RelativeLocation = BallTargetLocalStartPosition;
		RollAlpha = 0;
		AnimationDataComponent.MarbleBalance = RollAlpha;
		BalanceBoardBall.SetActorLocation(BallResetSpawnposition.GetWorldLocation());
		Marble.SetActorLocation(BallResetSpawnposition.GetWorldLocation());
		Marble.Mesh.SetRelativeRotation(FRotator::ZeroRotator);
		ReleasedBall = false;
		HasBroadCastedFailstate = false;
		OwningPlayer.ClearCameraClampSettingsByInstigator(this);
		OwningPlayer.ClearCameraSettingsByInstigator(BallTarget);

		System::SetTimer(this, n"AllowBallRoll", 3.f, false);
	}

	UFUNCTION()
	void AllowBallRoll()
	{
		bBlockBallRoll = false;
	}

	UFUNCTION()
	void ClearCameraSettings()
	{
		if(OwningPlayer != nullptr)
		{
			//why isnt this working!
			OwningPlayer.StopAllCameraShakes();
			OwningPlayer.StopForceFeedback(TensionRumble, n"SlacklineBalanceBoard");
			OwningPlayer.ClearCameraSettingsByInstigator(this);
			OwningPlayer.ClearCameraSettingsByInstigator(BallTarget);
		}
	}

	void SetBalanceInput(float Input) property
	{
		CurrentBalanceInput = Input;
	}

	float GetDesiredInput() property
	{
		return CurrentBalanceInput;
	}

	void CalcRollAlpha(float DeltaTime)
	{
		if (bBlockBallRoll)
		{
			RollAlpha = 0;
		}

		if (IsRunningFailstate)
		{
			BalanceSync.Value = RollAlpha;
		}

		else
		{
			RollVelocity += RandomRollVelocity * DeltaTime;

			if (OwningPlayer.HasControl())
			{
				if (FMath::Abs(DesiredInput) < 0.2f)
				{
					RollVelocity = FMath::Lerp(RollVelocity, 0.f, DeltaTime * 10.f);
				}

				else 
				{
					RollVelocity += DeltaTime * DesiredInput * 0.15f;
				}

				RollAlpha -= RollVelocity;
				RollAlpha = FMath::Clamp(RollAlpha, -1.f, 1.f);

				if (RollAlpha == 1.f || RollAlpha == -1.f)
				{
					RollVelocity =0;
				}
				BalanceSync.Value = RollAlpha;
			}
		}

		AnimationDataComponent.MarbleBalance = BalanceSync.Value;
		USlacklineMonoWheelAnimationDataComponent::Get(OwningPlayer.GetOtherPlayer()).MarbleBalance = BalanceSync.Value;
	}
}