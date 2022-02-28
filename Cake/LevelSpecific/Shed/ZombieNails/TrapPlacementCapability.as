import Cake.LevelSpecific.Shed.ZombieNails.ZombieMineActor;

class TrapPlacementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;

	UPROPERTY()
	TSubclassOf<AZombieMineActor> MineClass;

	AHazePlayerCharacter Player;
    AZombieMineActor Mine;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(ActionNames::WeaponAim))
            return EHazeNetworkActivation::ActivateLocal;
        else 
            return EHazeNetworkActivation::DontActivate;

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (!(IsActioning(ActionNames::WeaponAim)))
		    return EHazeNetworkDeactivation::DeactivateFromControl;
        
        return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        Mine = Cast<AZombieMineActor>(SpawnActor(MineClass));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Mine.ActivateMine();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
        if(Mine != nullptr)
        {
            Mine.SetActorLocation(Player.ActorLocation + FVector(0,0,150) + (Player.GetActorForwardVector() * 120.f));
        }
	}
}