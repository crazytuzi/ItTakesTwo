import Peanuts.Triggers.ActorTrigger;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;

class AParentBlobTrigger : AActorTrigger
{
	default TriggerOnActorClasses.Add(TSubclassOf<AHazeActor>(AParentBlob::StaticClass()));
}