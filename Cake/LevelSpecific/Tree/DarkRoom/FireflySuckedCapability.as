import Cake.LevelSpecific.Tree.DarkRoom.FireflySwarm;
import Cake.LevelSpecific.Tree.DarkRoom.FireflyCatchCapability;

class UFireFlySuckedCapability : UHazeCapability

{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	AFireflySwarm CurSwarm;

	float DistanceToSwarm = 0.f;

	UFireflyFlightComponent FlightComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlightComp = UFireflyFlightComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (CurSwarm == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (DistanceToSwarm < CurSwarm.Range)
			return EHazeNetworkActivation::DontActivate;

		if (Player.IsAnyCapabilityActive(UFireflyCatchCapability::StaticClass()))
			return EHazeNetworkActivation::DontActivate;

		if (FlightComp.bIsLaunching)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (DistanceToSwarm > CurSwarm.SuckingSphereCollision.ScaledSphereRadius + 200.f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		if (DistanceToSwarm < CurSwarm.Range)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"CurSwarm", CurSwarm);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurSwarm = Cast<AFireflySwarm>(ActivationParams.GetObject(n"CurSwarm"));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (DistanceToSwarm > CurSwarm.SuckingSphereCollision.ScaledSphereRadius + 200.f)
			CurSwarm = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (HasControl())
		{
			UObject FireflySwarmTemp;
			if (ConsumeAttribute(n"CurrentFireflySwarm", FireflySwarmTemp))
			{
				CurSwarm = Cast<AFireflySwarm>(FireflySwarmTemp);
			}
			if (CurSwarm != nullptr)
				DistanceToSwarm = Player.GetDistanceTo(Cast<AFireflySwarm>(CurSwarm));
		}
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float ImpulseModifier = FMath::GetMappedRangeValueClamped(FVector2D(CurSwarm.SuckingSphereCollision.ScaledSphereRadius, CurSwarm.Range), FVector2D(0.2, 1), DistanceToSwarm);
		FVector ImpulseDirection = CurSwarm.ActorLocation - Player.ActorLocation;
		ImpulseDirection.Normalize();
		Player.AddImpulse(ImpulseDirection * ImpulseModifier * CurSwarm.MaxSuckForce);
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{

	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		if(IsActive())
		{
			FString DebugText = "";
			if(HasControl())
			{
				DebugText += "Control Side\n";
			}
			else
			{
				DebugText += "Slave Side\n";
			}
			return DebugText;
		}

		return "Not Active";
	}
}