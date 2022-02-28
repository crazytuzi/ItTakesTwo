import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MusicTechWall.MusicTechActorBase;

UCLASS(Abstract)
class AAnalogTapeRecorder : AMusicTechActorBase
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RecorderBase;

	UPROPERTY(DefaultComponent, Attach = RecorderBase)
	USceneComponent LeftWheelRoot;

	UPROPERTY(DefaultComponent, Attach = RecorderBase)
	USceneComponent RightWheelRoot;

	UPROPERTY(DefaultComponent, Attach = LeftWheelRoot)
	UStaticMeshComponent LeftWheel;

	UPROPERTY(DefaultComponent, Attach = RightWheelRoot)
	UStaticMeshComponent RightWheel;

	UPROPERTY(DefaultComponent, Attach = LeftWheel)
	UStaticMeshComponent LeftPlatform;

	UPROPERTY(DefaultComponent, Attach = RightWheel)
	UStaticMeshComponent RightPlatform;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedLeftWheelRotation;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedRightWheelRotation;

	UPROPERTY(DefaultComponent, Attach = LeftWheel)
	UHazeAkComponent LeftWheelHazeAkComp;

	UPROPERTY(DefaultComponent, Attach = RightWheel)
	UHazeAkComponent RightWheelHazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MoveAudioEvent;

	float LeftTargetRoll = 0.0f;
	float RightTargetRoll = 0.0f;

	UPROPERTY()
	bool bSwapWheelToRotate = false;

	UPROPERTY()
	float LeftWheelStartRotation = 0.f;

	UPROPERTY()
	float RightWheelStartRotation = 0.f;

	float TargetLeftRotationRate = 0.f;
	float CurrentLeftRotationRate = 0.f;

	float TargetRightRotationRate = 0.f;
	float CurrentRightRotationRate = 0.f;

	float WheelRotationRate = 10.f;

	UPROPERTY()
	bool bShouldSendAnimFloatParams = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		SetControlSide(Game::GetCody());

		LeftTargetRoll = LeftWheelRoot.WorldRotation.Roll;
		RightTargetRoll = RightWheelRoot.WorldRotation.Roll;

		LeftWheelHazeAkComp.HazePostEvent(MoveAudioEvent);
		RightWheelHazeAkComp.HazePostEvent(MoveAudioEvent);
	}

	UFUNCTION()
	void RotationRateUpdate(float LeftRotationRate, float RightRotationRate)
	{
		Super::RotationRateUpdate(LeftRotationRate, RightRotationRate);

		if (!bSwapWheelToRotate)
		{
			TargetLeftRotationRate = LeftRotationRate * WheelRotationRate;
			TargetRightRotationRate = RightRotationRate * WheelRotationRate;
		} else
		{
			TargetLeftRotationRate = RightRotationRate * WheelRotationRate;
			TargetRightRotationRate = LeftRotationRate * WheelRotationRate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{		
		LeftPlatform.SetWorldRotation(FRotator(0.f, ActorRotation.Yaw, 0.f));
		RightPlatform.SetWorldRotation(FRotator(0.f, ActorRotation.Yaw, 0.f));

		LeftWheelRoot.SetRelativeRotation(FRotator(0.f, 0.f, LeftWheelStartRotation));
		RightWheelRoot.SetRelativeRotation(FRotator(0.f, 0.f, RightWheelStartRotation));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(HasControl())
		{
			CurrentLeftRotationRate = FMath::FInterpTo(CurrentLeftRotationRate, TargetLeftRotationRate, DeltaTime, 2.5f);
			LeftTargetRoll += -CurrentLeftRotationRate;
			//LeftWheelRoot.AddLocalRotation(FRotator(0.f, 0.f, -CurrentLeftRotationRate));

			CurrentRightRotationRate = FMath::FInterpTo(CurrentRightRotationRate, TargetRightRotationRate, DeltaTime, 2.5f);
			RightTargetRoll += -CurrentRightRotationRate;
			//RightWheelRoot.AddLocalRotation(FRotator(0.f, 0.f, -CurrentRightRotationRate));

			//SyncedLeftWheelRotation.Value = RightWheelRoot.RelativeRotation.
			SyncedLeftWheelRotation.Value = LeftTargetRoll;
			SyncedRightWheelRotation.Value = RightTargetRoll;
		}
		else
		{
			CurrentLeftRotationRate = LeftTargetRoll - SyncedLeftWheelRotation.Value;
			CurrentRightRotationRate = RightTargetRoll - SyncedRightWheelRotation.Value;
			LeftTargetRoll = SyncedLeftWheelRotation.Value;
			RightTargetRoll = SyncedRightWheelRotation.Value;
			
			if (bShouldSendAnimFloatParams)
			{
				Game::GetCody().SetAnimFloatParam(n"LeftWheelRotation", SyncedLeftWheelRotation.Value);
				Game::GetCody().SetAnimFloatParam(n"RightWheelRotation", SyncedRightWheelRotation.Value);
			}
		}

		//for audio
		float LeftRotationRateNormalized = FMath::GetMappedRangeValueClamped(FVector2D(-1.6f, 1.6f), FVector2D(-1.0f, 1.0f), CurrentLeftRotationRate);
		float RightRotationRateNormalized = FMath::GetMappedRangeValueClamped(FVector2D(-1.6f, 1.6f), FVector2D(-1.0f, 1.0f), CurrentRightRotationRate);
		LeftWheelHazeAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Platform_AnalogTapeRecorder_RotationRate", LeftRotationRateNormalized);
		RightWheelHazeAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Platform_AnalogTapeRecorder_RotationRate", RightRotationRateNormalized);

		LeftWheelRoot.SetRelativeRotation(FRotator(0.0f, 0.0f, SyncedLeftWheelRotation.Value));
		RightWheelRoot.SetRelativeRotation(FRotator(0.0f, 0.0f, SyncedRightWheelRotation.Value));

		LeftPlatform.SetWorldRotation(FRotator(0.f, ActorRotation.Yaw, 0.f));
		RightPlatform.SetWorldRotation(FRotator(0.f, ActorRotation.Yaw, 0.f));

		
	}
}