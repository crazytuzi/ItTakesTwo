import Vino.Interactions.InteractionComponent;
import Vino.Interactions.AnimNotify_Interaction;

event void FOnOrbLightInteracted(bool IsMayInteracting);

class ARotatingOrbLightActor : AHazeActor
{
//Components
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LampBaseMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LampTopMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent SpotLightComp;

	UPROPERTY(DefaultComponent , Attach = Root)
	UInteractionComponent InteractComp;
	default InteractComp.RelativeLocation = FVector(0,0,100);
	default InteractComp.ActionShape.Type = EHazeShapeType::Box;
	default InteractComp.ActionShapeTransform.Scale3D = FVector(2,2,1);
	default InteractComp.FocusShapeTransform.Location = FVector(0,0,100);
	default InteractComp.FocusShapeTransform.Scale3D = FVector(5,5,5);

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;

//Variables
	UPROPERTY(Category = "Settings")
	float DefaultRotationSpeed = 20;
	UPROPERTY(Category = "Settings")
	float SpeedToAdd = 250;
	UPROPERTY(Category = "Settings")
	float SpeedLoss = 30;
	UPROPERTY(Category = "Settings")
	float SpeedLossFactor = 10;
	UPROPERTY(Category = "Settings")
	float MaxRotationSpeed = 1250.f;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UForceFeedbackEffect OnInteractForceFeedback;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent OrbHazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OrbLoopAudioEvent;

	UPROPERTY()
	FOnOrbLightInteracted OnInteractedEvent;

	bool bRotatingRight = true;
	float RotationSpeed = 0;

	FRotator LookAtRotation;

//Audio Variables - Components:

	//RotationSpeed normalized as a positive 0-1 value
	float NormalizedRotationSpeed = 0.f;

	UPROPERTY()
	UAnimSequence CodyPushAnim;
	UPROPERTY()
	UAnimSequence MayPushAnim;

	AHazePlayerCharacter PlayerActor;

	FHazeAnimNotifyDelegate CodyAnimNotifyDelegate;
	FHazeAnimNotifyDelegate MayAnimNotifyDelegate;

//Functions

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnActivated.AddUFunction(this, n"OnInteracted");

		FHazeTriggerCondition Condition;
		Condition.Delegate.BindUFunction(this, n"InteractionCondition");
		InteractComp.AddTriggerCondition(n"Grounded", Condition);
		OrbHazeAkComp.HazePostEvent(OrbLoopAudioEvent);
	}

	UFUNCTION()
	bool InteractionCondition(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
	{
		if(Player.MovementState.GroundedState != EHazeGroundedState::Grounded)
			return false;
		else
			return true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FRotator CurrentRotation = LampTopMesh.GetRelativeRotation();
		CurrentRotation = FRotator(CurrentRotation.Pitch, CurrentRotation.Yaw - (CalculateRotationSpeed(DeltaTime) * DeltaTime), CurrentRotation.Roll);
		LampTopMesh.SetRelativeRotation(CurrentRotation);

		FRotator CurrentLightRotation = SpotLightComp.GetRelativeRotation();
		CurrentLightRotation = FRotator(CurrentLightRotation.Pitch, CurrentLightRotation.Yaw - (CalculateRotationSpeed(DeltaTime) * DeltaTime), CurrentLightRotation.Roll);
		SpotLightComp.SetRelativeRotation(CurrentLightRotation);
		OrbHazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interactions_RotatingOrbLamp_Speed", NormalizedRotationSpeed);
	}

	UFUNCTION()
	void OnInteracted(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		InteractComp.Disable(n"InUse");

		PlayerActor = Player;

		FTransform AlignTransform;

		Player.CleanupCurrentMovementTrail();

		if(Player.IsCody())
		{
			Animation::GetAnimAlignBoneTransform(AlignTransform, CodyPushAnim, 0.f);	
		}
		else
		{
			Animation::GetAnimAlignBoneTransform(AlignTransform, MayPushAnim, 0.f);
		}

		float AlignOffset;
		AlignOffset = AlignTransform.Location.X;

		FVector AlignPosition = Player.ActorLocation - Root.WorldLocation;
		AlignPosition = AlignPosition.GetSafeNormal();
		AlignPosition *= AlignOffset;
		AlignPosition += Root.WorldLocation;

		FVector Direction = Root.WorldLocation - PlayerActor.ActorLocation;
		LookAtRotation = Math::MakeRotFromX(Direction);

		FRotator Rot = Player.ActorRotation;
		Rot.Yaw = LookAtRotation.Yaw;
		Player.SmoothSetLocationAndRotation(AlignPosition, Rot);

		if(PlayerActor.IsCody())
		{
			PlayAnimation(PlayerActor, CodyPushAnim);
			CodyAnimNotifyDelegate.BindUFunction(this, n"OnAnimationNotify");
			PlayerActor.BindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), CodyAnimNotifyDelegate);
		}
		else
		{
			PlayAnimation(PlayerActor, MayPushAnim);
			MayAnimNotifyDelegate.BindUFunction(this, n"OnAnimationNotify");
			PlayerActor.BindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), MayAnimNotifyDelegate);
		}


	}

	UFUNCTION()
	void OnAnimationNotify(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMesh, UAnimNotify AnimNotify)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);

		if(Player == nullptr)
			return;

		AddRotationSpeed();
		if(Player.IsCody())
		{
			bRotatingRight = true;
			Player.UnbindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), CodyAnimNotifyDelegate);
		}
		else
		{
			bRotatingRight = false;
			Player.UnbindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), MayAnimNotifyDelegate);
		}

		if(Player != nullptr)
		{
			OnInteractedEvent.Broadcast(Player.IsMay());

			if(OnInteractForceFeedback != nullptr)
				Player.PlayForceFeedback(OnInteractForceFeedback, false, false, n"OrbLightInteract");
		}
	}

	UFUNCTION()
	void AddRotationSpeed()
	{
		RotationSpeed += SpeedToAdd;
	}

	float CalculateRotationSpeed(float DeltaTime)
	{
		RotationSpeed -= (SpeedLoss + (RotationSpeed / SpeedLossFactor)) * DeltaTime;

		if(RotationSpeed < DefaultRotationSpeed)
			RotationSpeed = DefaultRotationSpeed;
		else if(RotationSpeed > MaxRotationSpeed)
			RotationSpeed = MaxRotationSpeed;

		//Audio Value
		NormalizedRotationSpeed = FMath::GetMappedRangeValueClamped(FVector2D(0.f, MaxRotationSpeed), FVector2D(0.f, 1.f), RotationSpeed);

		if(bRotatingRight)
			return RotationSpeed;
		else
			return -RotationSpeed;
	}

	UFUNCTION()
	void PlayAnimation(AHazePlayerCharacter Player, UAnimSequence AnimationToPlay)
	{
		FHazeAnimationDelegate BlendOutDelegate;
		BlendOutDelegate.BindUFunction(this, n"OnAnimationBlendOut");
		Player.PlayEventAnimation(Animation = AnimationToPlay, OnBlendingOut = BlendOutDelegate);
	}

	UFUNCTION()
	void OnAnimationBlendOut()
	{
		PlayerActor = nullptr;
		InteractComp.EnableAfterFullSyncPoint(n"InUse");
	}
}