import Cake.LevelSpecific.PlayRoom.PillowFort.SideInteractions.ShiftingLavaLampActor;
import Vino.Interactions.AnimNotify_Interaction;

class AShiftingLavaLampRemote : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent ControlMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ButtonRoot;

	UPROPERTY(DefaultComponent, Attach = ButtonRoot)
	UStaticMeshComponent ButtonMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ExitLocation1;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ExitLocation2;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SitLocation;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	TArray<AShiftingLavaLampActor> LavaLamps;

	UPROPERTY(Category = "Setup")
	FHazeTimeLike ButtonTimeLike;

	UPROPERTY(Category = "Setup")
	FHazeTimeLike TranslationTimeLike;

	FVector StartLocation;
	USceneComponent ExitComp;

	UPROPERTY()
	UAnimSequence CodyAnim;
	UPROPERTY()
	UAnimSequence MayAnim;

	UPROPERTY(Category = "Settings")
	bool AlignLocation = false;

	AHazePlayerCharacter InteractingPlayer;
	FHazeAnimNotifyDelegate AnimNotifyDelegate;

	float ButtonPressedZShift = -5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		
		FHazeTriggerCondition Condition;
		Condition.Delegate.BindUFunction(this, n"InteractionCondition");
		InteractComp.AddTriggerCondition(n"Grounded", Condition);

		if(LavaLamps.Num() != 0 && LavaLamps[0] != nullptr)
		{
			InteractComp.OnActivated.AddUFunction(this, n"OnInteracted");
		}

		ButtonTimeLike.BindUpdate(this, n"OnButtonUpdate");
		ButtonTimeLike.BindFinished(this, n"OnButtonTimeLikeFinished");
		TranslationTimeLike.BindUpdate(this, n"OnJumpUpdate");
	}

	UFUNCTION()
	bool InteractionCondition(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
	{
		if(Player.MovementState.GroundedState != EHazeGroundedState::Grounded)
			return false;
		else
			return true;
	}

	UFUNCTION()
	void OnInteracted(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		InteractComp.Disable(n"InUse");
		InteractingPlayer = Player;

		StartLocation = Player.ActorLocation;

		ExitComp = VerifyEndLocationToUse();

		Player.CleanupCurrentMovementTrail();

		if(AlignLocation)
		{
			FTransform AlignTransform;

			if(Player.IsCody())
				Animation::GetAnimAlignBoneTransform(AlignTransform, CodyAnim, 0.f);
			else
				Animation::GetAnimAlignBoneTransform(AlignTransform, MayAnim, 0.f);

			float AlignOffset;
			AlignOffset = AlignTransform.Location.X;
			FVector AlignPosition = Player.ActorLocation - Root.WorldLocation;
			AlignPosition = AlignPosition.GetSafeNormal();
			AlignPosition *= AlignOffset;
			AlignPosition += Root.WorldLocation;

			Player.SetActorLocation(AlignPosition);
		}

		FVector Direction = Root.WorldLocation - Player.ActorLocation;
		FRotator LookAtRotation = Math::MakeRotFromX(Direction);

		//Player.SetActorRotation(FRotator(Player.ActorRotation.Pitch, LookAtRotation.Yaw, Player.ActorRotation.Roll));

		if(Player.IsCody())
			PlayAnimation(Player, CodyAnim);
		else
			PlayAnimation(Player, MayAnim);
		
		AnimNotifyDelegate.BindUFunction(this, n"OnAnimationNotify");
		Player.BindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);

		TranslationTimeLike.PlayFromStart();
	}

	int ValidateShape()
	{
		int TargetShape;
		TargetShape = LavaLamps[0].GetRandomShapeForRemote();

		for(auto LavaLamp : LavaLamps)
		{
			if(TargetShape > LavaLamp.ShapePresets.Num())
			{
				TargetShape = LavaLamp.ShapePresets.Num();
			}
		}
		return TargetShape;
	}

	USceneComponent VerifyEndLocationToUse()
	{
		FVector Distance = InteractingPlayer.ActorLocation - ExitLocation1.WorldLocation;
		float DistanceToEndPoint1 = Distance.Size();

		Distance = InteractingPlayer.ActorLocation - ExitLocation2.WorldLocation;
		float DistanceToEndPoint2 = Distance.Size();

		if(DistanceToEndPoint1 < DistanceToEndPoint2)
			return ExitLocation1;
		else
			return ExitLocation2;

	}

	UFUNCTION()
	void OnAnimationNotify(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMesh, UAnimNotify AnimNotify)
	{
		Actor.UnbindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);

		OnButtonPressed();
	}

	UFUNCTION()
	void PlayAnimation(AHazePlayerCharacter Player, UAnimSequence AnimationToPlay)
	{
		Player.PlayEventAnimation(Animation = AnimationToPlay);
	}

	UFUNCTION()
	void OnBlendComplete()
	{
		InteractingPlayer = nullptr;
		ButtonTimeLike.ReverseFromEnd();
	}

	UFUNCTION()
	void OnButtonUpdate(float Value)
	{
		ButtonMesh.RelativeLocation = FVector(ButtonMesh.RelativeLocation.X, ButtonMesh.RelativeLocation.Y, ButtonPressedZShift * Value);
	}

	UFUNCTION()
	void OnJumpUpdate(float Value)
	{
		FVector Location = FMath::VLerp(StartLocation, ExitComp.WorldLocation, FVector(Value, Value, Value));
		float YawRotation = FMath::Lerp(InteractingPlayer.ActorRotation.Yaw, ExitComp.WorldRotation.Yaw, Value);
		InteractingPlayer.SetActorRotation(FRotator(InteractingPlayer.ActorRotation.Pitch, YawRotation, InteractingPlayer.ActorRotation.Roll));
		InteractingPlayer.SetActorLocation(Location);
	}

	void OnButtonPressed()
	{
		ButtonTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void OnButtonTimeLikeFinished()
	{
		if(!ButtonTimeLike.IsReversed())
		{
			if(HasControl())
			{
				int TargetShape = ValidateShape();

				for(auto LavaLamp : LavaLamps)
				{
					LavaLamp.SetNewShape(TargetShape);
				}
			}
		}
		else
		{
			InteractComp.Enable(n"InUse");
		}
	}
}