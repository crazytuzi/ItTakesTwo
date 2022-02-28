import Peanuts.Outlines.Outlines;
class AMayTeleportWatch : AHazeActor
{
	// UPROPERTY(DefaultComponent, RootComponent)
	// USceneComponent Root;

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UPoseableMeshComponent WatchPoseableMesh;
	
	// UPROPERTY()
	// USkeletalMesh WatchMesh;

	// USkeletalMeshComponent MeshToCopy;

	// UFUNCTION(BlueprintOverride)
	// void BeginPlay()
	// {
	// 	AttachToActor(Game::GetMay(), n"Root");
	// 	WatchPoseableMesh.SetSkeletalMesh(WatchMesh);
		
	// 	CreateMeshOutlineBasedOnPlayer(WatchPoseableMesh, Game::GetMay());

	// 	MeshToCopy = Game::GetMay().Mesh;
	// }

	// UFUNCTION(BlueprintOverride)
	// void EndPlay(EEndPlayReason EndPlayReason)
	// {
	// 	RemoveMeshOutlineFromMesh(WatchPoseableMesh);
	// }

	// UFUNCTION(BlueprintOverride)
	// void Tick(float DeltaTime)
	// {
	// 	if (MeshToCopy == nullptr)
	// 		return;

	// 	WatchPoseableMesh.CopyPoseFromSkeletalComponent(MeshToCopy);
	// 	SetActorHiddenInGame(Root.AttachParent.Owner.bHidden);
	// }
}