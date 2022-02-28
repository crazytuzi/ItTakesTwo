import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlantSwiper;
import Vino.PlayerHealth.PlayerHealthStatics;

class UBossControllablePlantSwiperCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	ABossControllablePlantSwiper Plant;

	float ArmLength = 500.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Plant = Cast<ABossControllablePlantSwiper>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Plant.bIsAlive)
		{
			return EHazeNetworkActivation::DontActivate; 
		}

		if(Plant.SoilPatch.CurrentSection != 1)
		{
			return EHazeNetworkActivation::DontActivate; 
		}

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		if(!Plant.bIsAlive)
		{
			return EHazeNetworkDeactivation::DeactivateLocal; 
		}

		if(Plant.SoilPatch.CurrentSection != 1)
		{
			return EHazeNetworkDeactivation::DeactivateLocal; 
		}
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Plant.SwiperCollider.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Plant.SwiperCollider.OnComponentBeginOverlap.Unbind(this, n"OnComponentBeginOverlap");

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if(!Plant.bIsRightArm)
		// {
		// 	Plant.OtherSwiperArm.CurrentMashProgress = Plant.CurrentMashProgress;
		// }		
	}

	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if(Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
			Plant.OnSwiperArmHitPlayer.Broadcast(Player);
			KillPlayer(Player, Plant.DeathEffect);
		}
	}
}
 