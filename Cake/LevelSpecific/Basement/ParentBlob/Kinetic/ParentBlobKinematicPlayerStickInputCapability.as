import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticBase;
import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticComponent;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;
import Peanuts.Aiming.AutoAimStatics;

class UParentBlobKinematicPlayerStickInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(n"KineticTargeting");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 50;
	
	AHazePlayerCharacter Player;
	UParentBlobKineticComponent KineticComponent;
	UParentBlobPlayerComponent ParentBlobComponent;

	bool bHasInput = false;
	float LastReceivedInputAngle = 0;
	FVector LastReceivedInput;
	FVector CurrentInputDir;
	int NetworkValidation = 0;
	float LastSendTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ParentBlobComponent = UParentBlobPlayerComponent::Get(Player);
		KineticComponent = UParentBlobKineticComponent::Get(ParentBlobComponent.ParentBlob);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		LastReceivedInputAngle = 0;
		LastReceivedInput = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FParentBlobKineticPlayerInputData& PlayerData = KineticComponent.PlayerInputData[int(Player.Player)];
		PlayerData.bHasSteeringInput = false;
		PlayerData.bSteeringIsToFindInteraction = false;
		PlayerData.TargetedInteraction = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FParentBlobKineticPlayerInputData& PlayerData = KineticComponent.PlayerInputData[int(Player.Player)];

		// Should we handle the lightballs manually
		PlayerData.bSteeringIsToFindInteraction = false;
		if(PlayerData.FreelyPickInteractionTarget)
		{
			if(PlayerData.TargetedInteraction != nullptr)
				PlayerData.bSteeringIsToFindInteraction = !PlayerData.bIsHolding;
			else
				PlayerData.bSteeringIsToFindInteraction = true;
		}

		if(HasControl())
		{
			AHazePlayerCharacter ScreenPlayer = SceneView::IsFullScreen() ? SceneView::GetFullScreenPlayer() : Player;
			const FRotator ControlRotation = ScreenPlayer.GetControlRotation();
					
			FVector Up = FVector::UpVector;
			FVector Forward = ControlRotation.ForwardVector.ConstrainToPlane(Up).GetSafeNormal();
			if (Forward.IsZero())
				Forward = ControlRotation.UpVector.ConstrainToPlane(Up).GetSafeNormal();
			
			const FVector Right = Up.CrossProduct(Forward) * FMath::Sign(ControlRotation.UpVector.DotProduct(Up));

			// TODO; Handle mouse input
			const FVector RawStick = GetAttributeVector(AttributeVectorNames::RightStickRaw);
			const FVector CurrentInput = (Forward * RawStick.Y) + (Right * RawStick.X);	

			if(RawStick.IsNearlyZero() || !Player.IsUsingGamepad())
			{
				if(bHasInput)
					NetSetInputActive(false);
			}
			else
			{
				if(!bHasInput)
					NetSetInputActive(true);

				if(PlayerData.bSteeringIsToFindInteraction)
					UpdateFreeInput(CurrentInput, Forward, Right);
				else
					UpdateRelativeToInteractionInput(CurrentInput);
			}
		}

		
		if(PlayerData.bSteeringIsToFindInteraction)
		{
			if(bHasInput)
			{
				if(!PlayerData.bHasSteeringInput)
					PlayerData.InputAngle = LastReceivedInputAngle;
				else
					PlayerData.InputAngle = FMath::FInterpTo(PlayerData.InputAngle, LastReceivedInputAngle, DeltaTime, 4.f);

				PlayerData.bHasSteeringInput = true;	
			}
			else
			{
				PlayerData.InputAngle = 0;
				PlayerData.bHasSteeringInput = false;
			}
		}
		else
		{
			if(bHasInput)
			{
				if(!PlayerData.bHasSteeringInput)
					CurrentInputDir = LastReceivedInput;
				else
					CurrentInputDir = FMath::VInterpTo(CurrentInputDir, LastReceivedInput, DeltaTime, 10.f);

				PlayerData.bHasSteeringInput = true;	
			}
			else
			{
				CurrentInputDir = FVector::ZeroVector;
				PlayerData.bHasSteeringInput = false;
			}

			if(PlayerData.TargetedInteraction != nullptr)
			{
				FTransform InteractionTransform = PlayerData.TargetedInteraction.GetInteractionTransform(Player.Player);
				const FVector DirToInteraction = PlayerData.TargetedInteraction.GetRequiredInputDirection(Player.Player);
				PlayerData.InputAngle = DirToInteraction.DotProduct(CurrentInputDir);
			}
			else
			{
				PlayerData.InputAngle = -2.f;
			}
		}
 	}

	void UpdateRelativeToInteractionInput(FVector CurrentInput)
	{
		if(Time::GetGameTimeSince(LastSendTime) < 0.1f)
			return;

		LastSendTime = Time::GetGameTimeSeconds();
		NetSendInputDir(NetworkValidation + 1, CurrentInput);
	}

	void UpdateFreeInput(FVector CurrentInput, FVector Forward, FVector Right)
	{
		if(Time::GetGameTimeSince(LastSendTime) < 0.1f)
			return;

		LastSendTime = Time::GetGameTimeSeconds();
		const float DotInput = CurrentInput.DotProduct(Forward);
		const float DotLeftRight = CurrentInput.DotProduct(Right) >= 0 ? 1.f : -1.f;
		float InputAngle = Math::DotToDegrees(DotInput) * DotLeftRight;

		auto ActiveSettings = KineticComponent.DefaultInputSettings;
		const FParentBlobKineticInputSettingsData& Data = Player.IsMay() ? ActiveSettings.MaySettings : ActiveSettings.CodySettings;
		if(Data.bUseClamps)
		{
			InputAngle = FMath::ClampAngle(InputAngle, Data.InputClamp.Min, Data.InputClamp.Max);
		}

		NetSendInput(NetworkValidation + 1, InputAngle);
	}

	UFUNCTION(NetFunction)
	void NetSetInputActive(bool bStatus)
	{
		bHasInput = bStatus;
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSendInput(int ControlsideNetworkValidation, float Angle)
	{
		if(ControlsideNetworkValidation <= NetworkValidation)
			return;

		NetworkValidation = ControlsideNetworkValidation;
		LastReceivedInputAngle = Angle;
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSendInputDir(int ControlsideNetworkValidation, FVector Dir)
	{
		if(ControlsideNetworkValidation <= NetworkValidation)
			return;

		NetworkValidation = ControlsideNetworkValidation;
		LastReceivedInput = Dir;
	}
}