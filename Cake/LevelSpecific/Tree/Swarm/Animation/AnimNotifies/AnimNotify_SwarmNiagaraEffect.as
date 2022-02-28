import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

/* 
	Same as PlayNiagaraParticleEffect + Hides and destroys the effect 
	if the swarm isn't alive 
	or 
	if there aren't any particles at the location.

	(the effect is spawned before Notify() is called...)
*/ 

UCLASS(NotBlueprintable, meta = (DisplayName = "Play Swarm Niagara Particle Effect"))
class UAnimNotify_SwarmNiagaraEffect : UAnimNotify_HazeSwarmPlayNiagaraParticleEffect
{
	UFUNCTION(BlueprintOverride)
	bool ShouldSpawnNiagaraEffect(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		// preview
		const ASwarmActor Swarm = Cast<ASwarmActor>(MeshComp.Owner);
		if(Swarm == nullptr)
			return true;

		if((Swarm.IsAboutToDie() || Swarm.IsDead()))
			return false;

		USwarmSkeletalMeshComponent SwarmMeshComp = Cast<USwarmSkeletalMeshComponent>(MeshComp);
		if(SwarmMeshComp == nullptr)
			return true;

		// check if there are any particles at the align bone
		const FVector ExpectedPlayerLocation = SwarmMeshComp.GetSocketLocation(n"Align");
		bool bInside = Swarm.IsSwarmIntersectingSphere(ExpectedPlayerLocation, 200.f);
		// bool bInside = SwarmMeshComp.AreParticlesIntersectingSphere(ExpectedPlayerLocation, 150.f);

		// Print("bInside: " + bInside, 3.f, bInside ? FLinearColor::Green : FLinearColor::Red);
		// System::DrawDebugBox( 
		// 	// SwarmMeshComp.GetWorldLocation(),
		// 	SwarmMeshComp.GetWorldBoundOrigin(),
		// 	SwarmMeshComp.GetWorldBoundExtent(),
		// 	FLinearColor::Red,
		// 	// SwarmMeshComp.GetWorldRotation(),
		// 	FRotator::ZeroRotator,
		// 	3.f,
		// 	10.f
		// );
		// System::DrawDebugPoint(ExpectedPlayerLocation, 10.f, FLinearColor::Yellow, 3.f);
		// System::DrawDebugSphere(ExpectedPlayerLocation, 200.f, Duration = 3.f);
		return bInside;
	}
}