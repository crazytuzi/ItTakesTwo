import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseComponent;


class UWaterHoseManagerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"WaterHose");

	AHazePlayerCharacter Player;
	UWaterHoseComponent WaterHoseComp;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WaterHoseComp = UWaterHoseComponent::Get(Owner);
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
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		for(int i = 0; i < WaterHoseComp.WaterProjectiles.Num(); ++i)
		{
			WaterHoseComp.DeactivateProjectile(WaterHoseComp.WaterProjectiles[i]);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.UpdateActivationPointAndWidgets(UWaterHoseImpactComponent::StaticClass());

		if(WaterHoseComp.ActiveWaterProjectiles.Num() > 0)
		{
			FHazeTraceParams TraceParams = WaterHoseComp.GetProjectileTrace();
			if(IsDebugActive())
				TraceParams.DebugDrawTime = 0;	

			TArray<AWaterHoseProjectile> CollisionProjectiles = WaterHoseComp.ProjectilesToImpactTest;
			WaterHoseComp.ProjectilesToImpactTest.Reset();
			UpdateCollisionProjectiles(TraceParams, CollisionProjectiles);
			
			for(auto Projectile : WaterHoseComp.ActiveWaterProjectiles)
			{
				//Move the actor
				Projectile.UpdateProjectile(DeltaTime);
			}
		}
	}

	void UpdateCollisionProjectiles(FHazeTraceParams& TraceParams, const TArray<AWaterHoseProjectile>& CollisionProjectiles)
	{
		if(CollisionProjectiles.Num() == 0)
			return;

		TArray<AWaterHoseProjectile> PendingCollisionProjectiles;
		PendingCollisionProjectiles.Reserve(3);

		for(auto Projectile : CollisionProjectiles)
		{
			TraceParams.From = Projectile.LastWorldPosition;
			TraceParams.To = Projectile.GetActorLocation();

			bool bSetNextHeadTracer = false;
			FHazeHitResult MoveHit;
			if(TraceParams.Trace(MoveHit))
			{
				Projectile.OnWaterImpact.Broadcast(Projectile, MoveHit.FHitResult);
				bSetNextHeadTracer = true;
			}	
			else if(Projectile.CurrentLifeTimeLeft <= 0)
			{
				Projectile.OnWaterImpact.Broadcast(Projectile, MoveHit.FHitResult);
				bSetNextHeadTracer = true;
			}

			// We set the next tracer head
			if(bSetNextHeadTracer)
			{
				int NextIndex = Projectile.ArrayIndex + 1;
				if(NextIndex >= WaterHoseComp.WaterProjectiles.Num())
					NextIndex = 0;

				auto NextProjectile = WaterHoseComp.WaterProjectiles[NextIndex];
				if(NextProjectile.ParentIndex == Projectile.ArrayIndex)
				{
					NextProjectile.ParentIndex = -1;
					PendingCollisionProjectiles.Add(NextProjectile);
				}
			}
			else
			{
				WaterHoseComp.ProjectilesToImpactTest.Add(Projectile);
			}
		}

		UpdateCollisionProjectiles(TraceParams, PendingCollisionProjectiles);
	}

}