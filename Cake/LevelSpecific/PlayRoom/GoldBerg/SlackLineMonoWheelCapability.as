import Cake.LevelSpecific.PlayRoom.GoldBerg.SlackLineMonoWheel;

class SlackLineMonoWheelCapability : UHazeCapability
{
	ASlackLineWheel SlackLineMonoWheel;
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		UObject SlacklineCapabilityObj = GetAttributeObject(n"Slackline");

		if (SlacklineCapabilityObj != nullptr)
		{
			return EHazeNetworkActivation::ActivateLocal;
		}

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		UObject SlacklineCapabilityObj = GetAttributeObject(n"Slackline");

		if (SlacklineCapabilityObj != nullptr)
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}

		else
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"Movement", this);
		SlackLineMonoWheel = Cast<ASlackLineWheel>(GetAttributeObject(n"Slackline"));
		Player.CleanupCurrentMovementTrail();
		Player.AttachToComponent(SlackLineMonoWheel.MonowheelMeshComponent, SocketName = n"Totem", AttachmentRule = EAttachmentRule::SnapToTarget);

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"Movement", this);
		Player.ClearLocomotionAssetByInstigator(SlackLineMonoWheel);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		SlackLineMonoWheel.DesiredMovementInput(GetAttributeVector(AttributeVectorNames::MovementDirection).Y * -1);
		
		SetLocomotionData();
	}

	void SetLocomotionData()
	{
		if (Player.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData AnimData;
			AnimData.AnimationTag = n"UniCycle";
			Player.RequestLocomotion(AnimData);
		}
	}
}