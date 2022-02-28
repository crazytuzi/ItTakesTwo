

/*
  Create an editor-only visualizer mesh for a player,
  to indicate particular points in the editor scene.
*/
UFUNCTION()
UPlayerEditorVisualizerComponent CreatePlayerEditorVisualizer(
        USceneComponent AttachTo,
        EHazePlayer Player,
        FTransform RelativePosition,
		USkeletalMesh CustomMeshClass = nullptr
)
{
    auto Mesh = UPlayerEditorVisualizerComponent::Create(AttachTo.Owner);
    Mesh.AttachTo(AttachTo);
    Mesh.RelativeTransform = RelativePosition;
	
	Mesh.SetComponentTickEnabled(false);
    if (Player == EHazePlayer::Cody)
    {
		if(CustomMeshClass != nullptr)
			Mesh.SetSkeletalMesh(CustomMeshClass);
		else
        	Mesh.SetSkeletalMesh(Asset("/Game/Characters/Cody/Cody"));
    }
    else
    {
		if(CustomMeshClass != nullptr)
			Mesh.SetSkeletalMesh(CustomMeshClass);
		else
        	Mesh.SetSkeletalMesh(Asset("/Game/Characters/May/May"));
    }

	return Mesh;
}