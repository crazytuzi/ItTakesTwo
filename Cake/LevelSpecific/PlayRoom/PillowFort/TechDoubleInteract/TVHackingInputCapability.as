import Cake.LevelSpecific.PlayRoom.PillowFort.TechDoubleInteract.TVHackingActor;
import Cake.LevelSpecific.PlayRoom.PillowFort.TechDoubleInteract.TVHackingRemote;
import Vino.Tutorial.TutorialStatics;

class UTVHackingInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"HackingInput");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 30;

	AHazePlayerCharacter Player;
	ATVHackingActor TVActor;
	ATVHackingRemote RemoteActor;
	UHazeCrumbComponent CrumbComp;

	FVector2D PlayerInput;
	FVector2D TargetPosition;

	FVector CrumbedInputVector;

	bool bIsLeftPlayer;

	float NetworkRate = 0.075f;
	float NetworkNewTime = 0.f;

	float ReminderBarkTime = 3.f;
	float CurrentReminderBarkTimer = 0.f;

	FHazeAcceleratedVector2D AcceleratedPosition;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TVActor = Cast<ATVHackingActor>(GetAttributeObject(n"TVActor"));
		RemoteActor = Cast<ATVHackingRemote>(GetAttributeObject(n"TVRemoteActor"));
		CrumbComp = UHazeCrumbComponent::GetOrCreate(RemoteActor);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"InteractingLeftTV"))
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}
		else if(IsActioning(n"InteractingRightTV"))
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"InteractingLeftTV") && !IsActioning(n"InteractingRightTV"))
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(IsActioning(n"InteractingLeftTV"))
		{
			bIsLeftPlayer = true;

			TargetPosition = TVActor.Player1Position;

			if(!HasControl())
				AcceleratedPosition.SnapTo(TVActor.Player1Position, FVector2D::ZeroVector);
		}
		else if (IsActioning(n"InteractingRightTV"))
		{
			bIsLeftPlayer = false;

			TargetPosition = TVActor.Player2Position;

			if(!HasControl())
				AcceleratedPosition.SnapTo(TVActor.Player2Position, FVector2D::ZeroVector);
		}

		if(TVActor.TVState == ETVStateEnum::StartScreen)
		{
			Player.ShowTutorialPrompt(RemoteActor.StickTutorial, this);
			Player.ShowCancelPrompt(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.RemoveTutorialPromptByInstigator(this);
		Player.RemoveCancelPromptByInstigator(this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		CurrentReminderBarkTimer = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			PlayerInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

			HandleInput(PlayerInput, DeltaTime);

			NetworkVerify(DeltaTime);

			if(WasActionStarted(ActionNames::ButtonMash))
			{
				NetSetButtonAnimParam();
			}

			if(IsActioning(ActionNames::Cancel) && !IsActioning(n"LockedIntoInteraction") && ActiveDuration > 0.1f)
			{
				if(bIsLeftPlayer)
					Player.SetCapabilityActionState(n"InteractingLeftTV", EHazeActionState::Inactive);
				else
					Player.SetCapabilityActionState(n"InteractingRightTV", EHazeActionState::Inactive);
			}

		}
		else
		{
			AcceleratedPosition.AccelerateTo(TargetPosition, 0.5f, DeltaTime);

			if(bIsLeftPlayer)
			{
				TVActor.Player1Position = AcceleratedPosition.Value;
			}
			else
			{
				TVActor.Player2Position = AcceleratedPosition.Value;
			}
		}
	}

	void HandleInput(FVector2D PlayerInput, float DeltaTime)
	{
		if(bIsLeftPlayer)
		{
			TVActor.Player1Position = CalculateTranslation(TVActor.Player1Position, PlayerInput, DeltaTime);
		}
		else
		{
			TVActor.Player2Position = CalculateTranslation(TVActor.Player2Position, PlayerInput, DeltaTime);
		}
	}

	FVector2D CalculateTranslation(FVector2D Position, FVector2D Input, float DeltaTime)
	{
		FVector2D NewPosition = Position;
		NewPosition.X += (-Input.X * TVActor.PlayerSpeed) * DeltaTime;
		NewPosition.Y += (Input.Y * TVActor.PlayerSpeed) * DeltaTime;

		return NewPosition;
	}

	void NetworkVerify(float DeltaTime)
	{
		if(NetworkNewTime <= System::GameTimeInSeconds)
		{
			NetworkNewTime = System::GameTimeInSeconds + NetworkRate;

			if(bIsLeftPlayer)
				NetSetTargetPosition(TVActor.Player1Position);
			else
				NetSetTargetPosition(TVActor.Player2Position);
		}
	}

	UFUNCTION(NetFunction)
	void NetSetButtonAnimParam()
	{
		Player.SetAnimBoolParam(n"JoystickTrigger", true);
		RemoteActor.SetAnimBoolParam(n"JoystickTrigger", true);
	}

	UFUNCTION(NetFunction)
	void NetSetTargetPosition(FVector2D PositionToSet)
	{
		TargetPosition = PositionToSet;
	}
}