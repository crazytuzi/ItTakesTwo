//
//import Cake.LevelSpecific.Tree.Queen.Capabilities.QueenBaseCapability;
//
//UCLASS()
//class UQueenCoreApplyDamageTakenForcesCapbility : UQueenBaseCapability
//{
//	int ExplosionCounter = 0;
//
//	UFUNCTION(BlueprintOverride)
//	void OnActivated(FCapabilityActivationParams ActivationParams)
//	{
//		Queen.OnDamageTaken.AddUFunction(this, n"HandleDamageTaken");
//	}
//
//	UFUNCTION(BlueprintOverride)
//	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
//	{
//		Queen.OnDamageTaken.Unbind(this, n"HandleDamageTaken");
//	}
//
//	UFUNCTION()
//	void HandleDamageTaken(
//	FVector HitLocation,
//	USceneComponent HitComponent,
//	FName HitSocket,
//	float DamageTaken
//	)
//	{
//		if (ExplosionCounter > 0)
//			return;
//
//		Queen.Mesh.AddRadialImpulse(
//			HitLocation,
//			Settings.TakeDamage.SapExplosionRadius,
//			Settings.TakeDamage.SapExplosionStrength,
//			ERadialImpulseFalloff::RIF_Linear,
//			bVelChange = true
//		);
//
//		++ExplosionCounter;
//	}
//
// 	UFUNCTION(BlueprintOverride)
//	void TickActive(float DeltaSeconds)
//	{
//		if(ExplosionCounter > 0)
//			--ExplosionCounter;
//	}
//
//}