import Cake.LevelSpecific.Tree.SelfieCamera.SelfiePoseBase;
import Vino.Triggers.VOBarkPlayerLookAtTrigger;
enum EStageDirection
{
	Left,
	Right
}

ASelfieStage GetSelfieStage()
{
	TArray<ASelfieStage> SelfieStageArray;
	GetAllActorsOfClass(SelfieStageArray);

	return SelfieStageArray[0];
}

class ASelfieStage : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Stage;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent Face1;
	default Face1.bVisible = false;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent Face2;
	default Face2.bVisible = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent Face3;
	default Face3.bVisible = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkComp;

	UPROPERTY(Category = "Setup")
	TArray<ASelfiePoseBase> SelfiePoseInteractions;

	UPROPERTY(Category = "Setup")
	TArray<ASelfiePoseBase> SelfiePosesFace1;
	
	UPROPERTY(Category = "Setup")
	TArray<ASelfiePoseBase> SelfiePosesFace2;

	UPROPERTY(Category = "Setup")
	TArray<ASelfiePoseBase> SelfiePosesFace3;

	UPROPERTY(Category = "Setup")
	TArray<AVOBarkPlayerLookAtTrigger> LookAtVOTriggerArray;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StageRotate;

	FHazeAcceleratedFloat AccelRotSpeed;
	FHazeAcceleratedRotator AccelRotator;
	float RotTargetSpeed;
	float RotDefaultSpeed = 70.f;
	float RotSlowSpeed = 2.f;

	int StageIndex;

	TArray<FRotator> FacingDirection;
	default FacingDirection.SetNum(3);

	FRotator TargetRotation;

	FRotator CurrentRotation;

	bool bCanRotate;

	bool bSetAvailableInteractions;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FacingDirection[0] = Face1.WorldRotation; //starting rotation
		FacingDirection[1] = Face3.WorldRotation;
		FacingDirection[2] = Face2.WorldRotation;

		LookAtVOTriggerArray[0].DisableActor(this); //starting LookAt
		LookAtVOTriggerArray[1].DisableActor(this);
		LookAtVOTriggerArray[2].DisableActor(this);

		CurrentRotation = ActorRotation;

		AccelRotator.SnapTo(ActorRotation);

		StageIndex = 0;

		InitiateStage();
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bSetAvailableInteractions)
		{
			bSetAvailableInteractions = true;
		}

		if (bCanRotate)
		{
			AccelRotSpeed.AccelerateTo(RotTargetSpeed, 2.3f, DeltaTime);

			CurrentRotation = FMath::RInterpConstantTo(ActorRotation, TargetRotation, DeltaTime, AccelRotSpeed.Value);
			SetActorRotation(CurrentRotation);

			float Dot = TargetRotation.ForwardVector.DotProduct(ActorRotation.ForwardVector);

			if (Dot >= 0.9995f)
			{
				if (HasControl())
					NetEnableAvailableInteractions();
			}
			else if (Dot >= 0.75f)
			{
				RotTargetSpeed = RotSlowSpeed;
			}
		}
	}

	UFUNCTION()
	void InitiateStage()
	{
		for (ASelfiePoseBase Pose : SelfiePoseInteractions)
		{
			Pose.BindFunctions();
			Pose.OnStageTurnStarted.Broadcast();
		}

		LookAtVOTriggerArray[StageIndex].EnableActor(this);

		switch (StageIndex)
		{
			case 0:  
				for (ASelfiePoseBase Poses : SelfiePosesFace1)
					Poses.OnStageTurnCompleted.Broadcast();	
			break;

			case 1:
				for (ASelfiePoseBase Poses : SelfiePosesFace3)
					Poses.OnStageTurnCompleted.Broadcast();	
			break;

			case 2:
				for (ASelfiePoseBase Poses : SelfiePosesFace2)
					Poses.OnStageTurnCompleted.Broadcast();	
			break;
		}		
	}

	UFUNCTION(NetFunction)
	void NetEnableAvailableInteractions()
	{
		bCanRotate = false;

		LookAtVOTriggerArray[StageIndex].EnableActor(this);

		switch (StageIndex)
		{
			case 0:  
				for (ASelfiePoseBase Poses : SelfiePosesFace1)
					Poses.OnStageTurnCompleted.Broadcast();	
			break;

			case 1:
				for (ASelfiePoseBase Poses : SelfiePosesFace3)
					Poses.OnStageTurnCompleted.Broadcast();	
			break;

			case 2:
				for (ASelfiePoseBase Poses : SelfiePosesFace2)
					Poses.OnStageTurnCompleted.Broadcast();	
			break;
		}
	}

	UFUNCTION(NetFunction)
	void NetActivateStageRotation(EStageDirection Direction)
	{
		if (bCanRotate)
			return;

		for (ASelfiePoseBase Pose : SelfiePoseInteractions)
			Pose.OnStageTurnStarted.Broadcast();
		
		for (AVOBarkPlayerLookAtTrigger LookAt : LookAtVOTriggerArray)
		{
			if (!LookAt.IsActorDisabled())
				LookAt.DisableActor(this);
		}

		RotTargetSpeed = RotDefaultSpeed;

		AccelRotSpeed.SnapTo(0.f);

		bCanRotate = true;

		if (Direction == EStageDirection::Left)
		{
			if (StageIndex < FacingDirection.Num() - 1)
				StageIndex++;
			else
				StageIndex = 0;
		}
		else
		{
			if (StageIndex > 0)
				StageIndex--;
			else
				StageIndex = 2;			
		}

		TargetRotation = FacingDirection[StageIndex];

		AkComp.HazePostEvent(StageRotate);
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartTimeLine() {}
}