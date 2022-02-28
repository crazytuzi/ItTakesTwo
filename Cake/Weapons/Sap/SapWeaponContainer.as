
/*
	It's important to Robert that match and sap is handled in the same 
	way when it comes to Sequencer. Please let me know if you change this. Sydney
*/

class ASapWeaponContainer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;
	default Mesh.AddTag(ComponentTags::HideOnCameraOverlap);

	UFUNCTION(BlueprintEvent)
	void SetFuelPercent(float Percent)
	{
	}
}