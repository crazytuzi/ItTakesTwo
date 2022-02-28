import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlantHammer;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlantHammer_AnimNotify;

class UBossControllablePlantHammerSmashingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	ABossControllablePlantHammer Plant;

	bool bSmashing = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Plant = Cast<ABossControllablePlantHammer>(Owner);
		//Plant.HammerCollider.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");

		FHazeAnimNotifyDelegate HammerSmashDelegate;
		HammerSmashDelegate.BindUFunction(this, n"HammerSmashHappened");
		Owner.BindAnimNotifyDelegate(UAnimNotify_BossControllablePlantHammer::StaticClass(), HammerSmashDelegate);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Plant.bIsAlive)
		{
			return EHazeNetworkActivation::DontActivate; 
		}

		if(Plant.bFullyButtonMashed)
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

		if(Plant.bFullyButtonMashed)
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
		bSmashing = true;
	}

	UFUNCTION()
	void HammerSmashHappened(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		if(Actor != Owner)
			return;

		FVector HeadLocation = Plant.SkeletalMesh.GetSocketLocation(n"Head");
		float DistanceToMay = HeadLocation.DistXY(Game::GetMay().ActorLocation);
		float DistanceToCody = HeadLocation.DistXY(Game::GetCody().ActorLocation);

		if(DistanceToMay < Plant.HitRange)
		{
			Plant.OnHammerArmHitPlayer.Broadcast(Game::GetMay());
			KillPlayer(Game::GetMay(), Plant.DeathEffect);
		}
		if(DistanceToCody < Plant.HitRange)
		{
			Plant.OnHammerArmHitPlayer.Broadcast(Game::GetCody());
			KillPlayer(Game::GetCody(), Plant.DeathEffect);
		}

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bSmashing = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector HeadLocation = Plant.SkeletalMesh.GetSocketLocation(n"Head");
		float DistanceToMay = HeadLocation.DistXY(Game::GetMay().ActorLocation);
		float DistanceToCody = HeadLocation.DistXY(Game::GetCody().ActorLocation);

		if(DistanceToMay < Plant.PlayerInRangeDistance || DistanceToCody < Plant.PlayerInRangeDistance)
		{
			Plant.bPlayerIsInRange = true;
		}
		else
		{
			Plant.bPlayerIsInRange = false;			
		}
	}

}
