import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;
import Vino.Camera.Capabilities.CameraTags;
import Cake.LevelSpecific.SnowGlobe.SnowTurtle.SnowTurtleBaby;

class USnowTurtlePlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerTurtleMagnet");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UMagneticPlayerComponent PlayerMagnetComp;
	ASnowTurtleBaby TargetSnowTurtle;

	FVector MagnetTarget;

	float CurrentMagnetPower;
	float MaxMagnetPower = 2000.f;

	float MaxPushDistance = 1050.f;
	float MaxPullDistance = 500.f;

	float MaxMagnetDistance = 2200.f;
	float CurrentMagnetDistance;

	float PowerAdd = 45.f;

	bool bIsPulling;

	bool bHasBlockedMagnet;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		if (PlayerMagnetComp.GetActivatedMagnet() == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!PlayerMagnetComp.ActivatedMagnet.Owner.ActorHasTag(n"Turtle"))
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		if (PlayerMagnetComp.GetActivatedMagnet() != nullptr)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);
		ASnowTurtleBaby CurrentSnowTurtle  = Cast<ASnowTurtleBaby>(PlayerMagnetComp.ActivatedMagnet.Owner);
		OutParams.AddObject(n"Turtle", CurrentSnowTurtle);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CameraTags::ChaseAssistance, this);

		TargetSnowTurtle = Cast<ASnowTurtleBaby>(ActivationParams.GetObject(n"Turtle"));

		if (TargetSnowTurtle == nullptr)
			return;

		if (Player.IsCody())
		{
			if	(TargetSnowTurtle.MagnetComponent.Polarity == EMagnetPolarity::Plus_Red && !TargetSnowTurtle.bHaveEnteredNestArea)
				bIsPulling = false;
			else if (TargetSnowTurtle.MagnetComponent.Polarity == EMagnetPolarity::Minus_Blue && !TargetSnowTurtle.bHaveEnteredNestArea)
				bIsPulling = true;
		}
		else
		{
			if	(TargetSnowTurtle.MagnetComponent.Polarity == EMagnetPolarity::Plus_Red && !TargetSnowTurtle.bHaveEnteredNestArea)
				bIsPulling = true;
			else if (TargetSnowTurtle.MagnetComponent.Polarity == EMagnetPolarity::Minus_Blue && !TargetSnowTurtle.bHaveEnteredNestArea)
				bIsPulling = false;
		}

		TargetSnowTurtle.SnowMagnetInfoComp.PlayerArray.Add(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CameraTags::ChaseAssistance, this);
		ResetMagnetPower();

		TargetSnowTurtle.SnowMagnetInfoComp.PlayerArray.Remove(Player);

		CurrentMagnetDistance = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (TargetSnowTurtle == nullptr)
			return;

		if (!TargetSnowTurtle.bHaveEnteredNestArea)
			MaxMagnetPower = 2000.f;
		else
			MaxMagnetPower = 0.f;

		if (CurrentMagnetPower < MaxMagnetPower)
			CurrentMagnetPower += PowerAdd;
		else
			CurrentMagnetPower = MaxMagnetPower;

		if (bIsPulling)
			PullTarget();
		else
			PushTarget();

		FVector TargetDirection = TargetSnowTurtle.ActorLocation - Player.ActorLocation;
		CurrentMagnetDistance =  TargetDirection.Size();

		if (CurrentMagnetDistance >= MaxMagnetDistance)
			PlayerMagnetComp.DeactivateMagnetLockon(Player);
	}

	UFUNCTION()
	void PushTarget()
	{
		FVector Direction = TargetSnowTurtle.ActorLocation - Player.ActorLocation; 
		float Distance = Direction.Size() / 2.f;
		float PowerPercent = MaxPushDistance / Distance;
		Direction.Normalize();
	
		TargetSnowTurtle.SnowMagnetInfoComp.PushPowerToAdd = FVector(Direction.X, Direction.Y, 0.f) * CurrentMagnetPower * PowerPercent;
	}

	UFUNCTION()
	void PullTarget()
	{
		FVector Direction = Player.ActorLocation - TargetSnowTurtle.ActorLocation;
		float Distance = Direction.Size() / 2.f;
		float PowerPercent = Distance / MaxPullDistance;
		Direction.Normalize();

		TargetSnowTurtle.SnowMagnetInfoComp.PullPowerToAdd = FVector(Direction.X, Direction.Y, 0.f) * CurrentMagnetPower * PowerPercent;
	}

	UFUNCTION()
	void ResetMagnetPower()
	{
		CurrentMagnetPower = 0.f;

		if (bIsPulling)
			TargetSnowTurtle.SnowMagnetInfoComp.PullPowerToAdd = 0.f;
		else
			TargetSnowTurtle.SnowMagnetInfoComp.PushPowerToAdd = 0.f;
	}
}