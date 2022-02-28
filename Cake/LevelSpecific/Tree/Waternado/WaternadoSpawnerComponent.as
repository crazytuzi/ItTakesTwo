import Cake.LevelSpecific.Tree.Waternado.Waternado;
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

/*

	Used in spawning an Nado from the wasp swarm.

*/

event void FSequencerNadoTransition(ASwarmActor Swarm, AWaternado WaterNado);

UCLASS(HideCategories = "Cooking ComponentReplication Tags Sockets Clothing ClothingSimulation AssetUserData Mobile MeshOffset Collision Activation")
class UWaternadoSpawnerComponent : UActorComponent
{
	UPROPERTY(Category = "Swarm Events", ShowOnActor, meta = (BPCannotCallEvent))
	FSequencerNadoTransition PlayCutsceneEvent;

	UPROPERTY(Category = "Nado")
	TSubclassOf<AWaternado> WaterSpoutToSpawn;

	UPROPERTY(Category = "Nado")
	AWaternado OptionalExistingWaternadoInstance = nullptr;

	// will trace against this actor to figure out water height
	UPROPERTY(Category = "Nado")
	ALandscapeProxy WaterSurfaceActor;

	/* Can be seen as the start node initially. It will 
		automatically find the nearest if this is left unassgined */
	UPROPERTY(Category = "Nado")
	AWaternadoNode StartNode = nullptr;

	AWaternado SpawnWaternado()
	{
		if(OptionalExistingWaternadoInstance != nullptr)
			return OptionalExistingWaternadoInstance;

		if(!WaterSpoutToSpawn.IsValid())
			return nullptr;

		auto ActorSpawned = SpawnActor(
			WaterSpoutToSpawn.Get(),
			Owner.GetActorLocation(),
			// FRotator::ZeroRotator,
			Owner.GetActorRotation(),
			NAME_None,
			false,
			Owner.Level
		);

		AWaternado Waternado = Cast<AWaternado>(ActorSpawned);
		Waternado.MakeNetworked(this);

		Waternado.MoveComp.WaterSurfaceActor = WaterSurfaceActor;

		if(StartNode != nullptr)
		{
			Waternado.MoveComp.CurrentNode = StartNode;
			Waternado.MoveComp.InitSplineMovement();
		}

		return Waternado;
	}

}