import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;
import Vino.Movement.MovementSystemTags;

class UIceSkatingGroundFindCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;
	UHazeMovementComponent MoveComp;

	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 5;

	FIceSkatingGroundFindSettings GroundFindSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.IsGrounded())
		{
			SkateComp.ProjectedGroundHit = MoveComp.DownHit;
		}
		// Not used so removed for now, Tyko
		// else
		// {
		// 	TArray<EObjectTypeQuery> Types;
		// 	Types.Add(EObjectTypeQuery::WorldStatic);
		// 	Types.Add(EObjectTypeQuery::WorldDynamic);

		// 	FHazeTraceParams Trace;
		// 	Trace.InitWithTraceChannel(ETraceTypeQuery::Visibility);
		// 	Trace.From = Player.ActorLocation - MoveComp.WorldUp * 50.f;
		// 	Trace.To = Player.ActorLocation - MoveComp.WorldUp * GroundFindSettings.SearchHeight;

		// 	FHazeHitResult Hit;
		// 	Trace.Trace(Hit);

		// 	if (Hit.bBlockingHit)
		// 	{
		// 		//SkateComp.ProjectedGroundHit = Hit.FHitResult;
		// 	}
		// }
	}
}