import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Vino.Checkpoints.Checkpoint;
import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticComponent;

class UParentBlobPlayerComponent : UActorComponent
{
	AParentBlob ParentBlob;

	UPROPERTY()
	TSubclassOf<AParentBlob> ParentBlobClass;

	UPROPERTY()
	UHazeCapabilitySheet ParentBlobSheet;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);

		TArray<AParentBlob> Blobs;
		GetAllActorsOfClass(Blobs);
		if(Blobs.Num() == 0)
		{
			auto ControllingPlayer = Game::GetMay();
			ParentBlob = Cast<AParentBlob>(SpawnActor(ParentBlobClass, ControllingPlayer.ActorLocation, ControllingPlayer.ActorRotation));
			ParentBlob.MakeNetworked(this, n"ParentBlob");
			ParentBlob.AddCapabilitySheet(ParentBlobSheet);	
			ControllingPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
		}
		else
		{
			ParentBlob = Blobs[0];
		}
	
		Player.AttachToActor(ParentBlob);
	}
};

UFUNCTION(Category = "ParentBlob", BlueprintPure)
AParentBlob GetActiveParentBlobActor()
{
	auto Component = UParentBlobPlayerComponent::Get(Game::GetMay());
	if (Component != nullptr)
		return Component.ParentBlob;
	return nullptr;
}

UFUNCTION(Category = "ParentBlob")
void TeleportParentBlobToCheckpoint(ACheckpoint Checkpoint)
{
	if (GetActiveParentBlobActor() == nullptr)
		return;

	if (Checkpoint == nullptr)
		return;

	GetActiveParentBlobActor().TeleportActor(Checkpoint.ActorLocation, Checkpoint.ActorRotation);
}