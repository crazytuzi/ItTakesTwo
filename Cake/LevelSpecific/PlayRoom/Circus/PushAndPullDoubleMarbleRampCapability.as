import Cake.LevelSpecific.PlayRoom.Circus.PushableAndPullableDoubleMarbleRamp;
import Vino.Tutorial.TutorialStatics;

UCLASS(Abstract)
class UPushAndPullDoubleMarbleRampCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::GamePlay;

	AHazePlayerCharacter Player;

    UHazeBaseMovementComponent Movement;

    APushableAndPullableDoubleMarbleRamp CurrentRamp;

	UHazeTriggerComponent Interaction;

	UPROPERTY(Category = "Animation")
	UAnimSequence CodyStruggleAnimation;
	UPROPERTY(Category = "Animation")
	UAnimSequence CodyPullStruggleAnimation;
	UPROPERTY(Category = "Animation")

	UAnimSequence CodyPushAnimation;
	UPROPERTY(Category = "Animation")
	UAnimSequence CodyIdleAnimation;
	UPROPERTY(Category = "Animation")
	UAnimSequence MayPushAnimation;
    UPROPERTY(Category = "Animation")
	UAnimSequence MayIdleAnimation;
    UPROPERTY(Category = "Animation")
	UAnimSequence CodyPullAnimation;
	UPROPERTY(Category = "Animation")
	UAnimSequence MayPullAnimation;
	UPROPERTY(Category = "Animation")
	UAnimSequence MayStruggleAnimation;
	UPROPERTY(Category = "Animation")
	UAnimSequence MayPullStruggleAnimation;
	

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if(IsActioning(n"PushingDoubleRamp"))
            return EHazeNetworkActivation::ActivateLocal;
        else
            return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if(IsActioning(ActionNames::Cancel))
		    return EHazeNetworkDeactivation::DeactivateFromControl;
        else
            return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        CurrentRamp = Cast<APushableAndPullableDoubleMarbleRamp>(GetAttributeObject(n"DoubleRamp"));
		Interaction = Cast<UHazeTriggerComponent>(GetAttributeObject(n"Interaction"));

        Player.BlockCapabilities(n"Movement", this);
		Player.BlockCapabilities(CapabilityTags::TotemMovement, this);

        UAnimSequence PushAnimation = Player.IsCody() ? CodyStruggleAnimation : MayStruggleAnimation;

        Player.PlaySlotAnimation(Animation = PushAnimation, BlendTime = 0.2f, bLoop = true);

		//Player.TriggerMovementTransition()
		Player.AttachToComponent(CurrentRamp.Base, AttachmentRule = EAttachmentRule::KeepWorld);

		Player.SetActorRelativeTransform(Interaction.RelativeTransform);


		ShowCancelPrompt(Player, this);
	}

	FRotator CalculateDirectionToLocationFromPlayer(FVector Location, AHazePlayerCharacter Player)
	{
		FVector Direction = FVector(Location.X - Player.ActorLocation.X, Location.Y -  Player.ActorLocation.Y, 0);
		Direction.Normalize();
		FRotator NewRotator = Math::MakeRotFromX(Direction);
		return NewRotator;
	}

	void PlayStruggleAnimation()
	{
		UAnimSequence StruggleAnimation = Player.IsCody() ? CodyStruggleAnimation : MayStruggleAnimation;

		if(!Player.IsPlayingAnimAsSlotAnimation(StruggleAnimation))
		{
			Player.PlaySlotAnimation(Animation = StruggleAnimation, BlendTime = 0.2f, bLoop = true);
		}
	}

	void PlayIdleAnimation()
	{
		UAnimSequence StruggleAnimation = Player.IsCody() ? CodyIdleAnimation : MayIdleAnimation;
		if(!Player.IsPlayingAnimAsSlotAnimation(StruggleAnimation))
		{
			Player.PlaySlotAnimation(Animation = StruggleAnimation, BlendTime = 0.2f, bLoop = true);
		}
	}

	void PlayPullStruggleAnimation()
	{
		UAnimSequence StruggleAnimation = Player.IsCody() ? CodyPullStruggleAnimation : MayPullStruggleAnimation;

		if(!Player.IsPlayingAnimAsSlotAnimation(StruggleAnimation))
			Player.PlaySlotAnimation(Animation = StruggleAnimation, BlendTime = 0.2f, bLoop = true);
	}

	void PlayPushAnimation()
	{
		UAnimSequence PushAnimation = Player.IsCody() ? CodyPushAnimation : MayPushAnimation;

		if(!Player.IsPlayingAnimAsSlotAnimation(PushAnimation))
			Player.PlaySlotAnimation(Animation = PushAnimation, BlendTime = 0.2f, bLoop = true);
	}

    void PlayPullAnimation()
	{
		UAnimSequence PullAnimation = Player.IsCody() ? CodyPullAnimation : MayPullAnimation;

		if(!Player.IsPlayingAnimAsSlotAnimation(PullAnimation))
		{
			Player.PlaySlotAnimation(Animation = PullAnimation, BlendTime = 0.2f, bLoop = true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(CapabilityTags::TotemMovement, this);
        Player.StopAnimation();
        Player.SetCapabilityActionState(n"PushingDoubleRamp", EHazeActionState::Inactive);
        Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
        CurrentRamp.ReleaseRamp(Interaction, Player);
		CurrentRamp.ResetPushPower(Player);

		RemoveCancelPromptByInstigator(Player, this);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
        CurrentRamp.UpdatePushPower(Player, MoveDirection);

		float MoveDir = MoveDirection.GetSafeNormal().DotProduct(Player.ActorForwardVector);

		UpdateAnimations(MoveDir * MoveDirection.Size());
	}

	void UpdateAnimations(float MoveDir)
	{
		bool IsAtFront = (CurrentRamp.PlayerAtFront == Owner);
		float Movedelta = CurrentRamp.MoveDelta * -1;

		if (IsAtFront)
		{
			if (Movedelta > 1.f)
			{
				PlayPullAnimation();
			}

			else if (Movedelta < -1.f)
			{
				PlayPushAnimation();
			}

			else if (MoveDir > 0.2f)
			{
				PlayStruggleAnimation();
			}
			else if (MoveDir < -0.2f)
			{
				PlayPullStruggleAnimation();
			}
			else
			{
				PlayIdleAnimation();
			}
		}

		else 
		{
			if (Movedelta > 1.f)
			{
				PlayPushAnimation();

			}
			else if (Movedelta < -1.f)
			{
				PlayPullAnimation();
			}
			else if (MoveDir > 0.2f)
			{
				PlayStruggleAnimation();
			}
			else if (MoveDir < -0.2f)
			{
				PlayPullStruggleAnimation();
			}
			else
			{
				PlayIdleAnimation();
			}
		}
	}
}