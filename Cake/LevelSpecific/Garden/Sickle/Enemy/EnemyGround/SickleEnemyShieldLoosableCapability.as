import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyGround.SickleEnemyGroundComponent;

class USickleEnemyShieldLoosableCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 90;
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	ASickleEnemy AiOwner;
	USickleEnemyGroundComponent AiComponent;
	UVineImpactComponent VineImpactComponent;

	float TimeLeftToDropShield = 0;
	bool bHasLockedMayAsTarget = false;
	float TargetRadialProgress = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyGroundComponent::Get(AiOwner);
		VineImpactComponent = UVineImpactComponent::Get(AiOwner);
		VineImpactComponent.CurrentWidgetRadialProgress = 0;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(VineImpactComponent.CurrentWidgetRadialProgress != TargetRadialProgress)
		{
			const float Multiplier = TargetRadialProgress > 0 ? 3.f : 1.f;
			VineImpactComponent.CurrentWidgetRadialProgress = FMath::FInterpConstantTo(VineImpactComponent.CurrentWidgetRadialProgress, TargetRadialProgress, DeltaTime, Multiplier);
			if(VineImpactComponent.CurrentWidgetRadialProgress > 0.99f)
				VineImpactComponent.CurrentWidgetRadialProgress = 1.f;
		}

		TargetRadialProgress = 0;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!AiComponent.bHasShield)
			return EHazeNetworkActivation::DontActivate;

		if(!AiComponent.bCanDropShield)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!AiComponent.bHasShield)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!AiComponent.bCanDropShield)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {	
		VineImpactComponent.AttachmentMode = EVineAttachmentType::Component;
		AiOwner.SickleCuttableComp.bInvulnerable = true;
		AiOwner.SickleCuttableComp.BonusScoreMultiplier = 1.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		VineImpactComponent.AttachmentMode = EVineAttachmentType::Whip;
		AiOwner.SickleCuttableComp.bInvulnerable = false;
		AiOwner.SickleCuttableComp.BonusScoreMultiplier = 0.5f;
	}  

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		auto May = Game::GetMay();
		if(!bHasLockedMayAsTarget)
		{
			if(AiOwner.SickleCuttableComp.IsTargetedBy(May))
			{
				AiOwner.LockPlayerAsTarget(May);
				bHasLockedMayAsTarget = true;
			}
		}
		else if(bHasLockedMayAsTarget)
		{
			if(!AiOwner.SickleCuttableComp.IsTargetedBy(May))
			{
				AiOwner.SetFreeTargeting();
				bHasLockedMayAsTarget = false;
			}
		}

		// Vine stuff happens on codys side...
		auto Cody = Game::GetCody();
		if(Cody.HasControl())
		{
			auto VineImpact = UVineImpactComponent::Get(Owner);
			//VineImpact.CurrentWidgetRadialProgress = 0;
			if(AiOwner.bIsBeeingHitByVine)
			{
				TimeLeftToDropShield += DeltaTime;
				TargetRadialProgress = FMath::Lerp(0.33f, 1.f, FMath::Min(TimeLeftToDropShield / AiComponent.TimeToDropShield, 1.f));
				VineImpactComponent.CurrentWidgetRadialProgress = TargetRadialProgress;
				
				// We add network ping here to make it snappier
				if(TimeLeftToDropShield >= AiComponent.TimeToDropShield)
				{	
					UHazeCrumbComponent::Get(Cody).LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"DropShield"), FHazeDelegateCrumbParams());
				}
			}
			else if(TimeLeftToDropShield > 0)
			{
				TimeLeftToDropShield = 0;
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void DropShield(FHazeDelegateCrumbData CrumbData)
	{
		if(AiComponent.ShieldDestroyedEffect != nullptr)
			Niagara::SpawnSystemAtLocation(AiComponent.ShieldDestroyedEffect, AiOwner.GetActorCenterLocation());
		
		if(AiComponent.NakedType != nullptr)
			AiOwner.Mesh.SetSkeletalMesh(AiComponent.NakedType);

		AiOwner.ApplyStunnedDuration(AiComponent.ShieldLostStunnedDuration);
		AiComponent.bHasShield = false;
	}
}