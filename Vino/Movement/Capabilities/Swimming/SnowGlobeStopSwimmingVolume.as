import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Peanuts.Fades.FadeManagerComponent;

event void FOnStopSwimmingVolumeEntered(AHazePlayerCharacter Player, bool bWasSwimming);
event void FOnStopSwimmingVolumeExited(AHazePlayerCharacter Player);

class ASnowGlobeStopSwimmingVolume : APostProcessVolume
{	
	UPROPERTY(DefaultComponent, Attach = BrushComponent)
	UStaticMeshComponent OptionalMesh;
	default OptionalMesh.SetCollisionProfileName(n"Trigger");
	default OptionalMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default OptionalMesh.bHiddenInGame = true;

	UPROPERTY()
	FOnStopSwimmingVolumeEntered OnStopSwimmingVolumeEntered;
	UPROPERTY()
	FOnStopSwimmingVolumeExited OnStopSwimmingVolumeExited;

	// Misc
	default Settings.SetbOverride_SceneColorTint(true);
	default Settings.SceneColorTint = FLinearColor(1.f, 1.f, 1.f);

	default Priority = 3.f;
	default BlendRadius = 0.f;

	default BrushComponent.SetCollisionProfileName(n"Trigger");

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (OptionalMesh.StaticMesh != nullptr)
			OptionalMesh.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		// If a mesh has been selected, swimming should be disabled using the mesh instead of the volume
		if (OptionalMesh.StaticMesh != nullptr)
		{
			OptionalMesh.OnComponentBeginOverlap.AddUFunction(this, n"BrushBeginOverlap");
			OptionalMesh.OnComponentEndOverlap.AddUFunction(this, n"BrushEndOverlap");	
		}	
		else
		{
			BrushComponent.OnComponentBeginOverlap.AddUFunction(this, n"BrushBeginOverlap");
			BrushComponent.OnComponentEndOverlap.AddUFunction(this, n"BrushEndOverlap");
		}	
	}	

	UFUNCTION()
	void BrushBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		USnowGlobeSwimmingComponent SwimComp = USnowGlobeSwimmingComponent::Get(OtherActor); 
		if (SwimComp == nullptr)
			return;

		bool bWasSwimming = SwimComp.bWasActuallyInWater;
		SwimComp.EnteredStopSwimmingVolume();
		OnStopSwimmingVolumeEntered.Broadcast(Player, bWasSwimming);
	}

	UFUNCTION()
    void BrushEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		USnowGlobeSwimmingComponent SwimComp = USnowGlobeSwimmingComponent::Get(OtherActor);
		if (SwimComp == nullptr)
			return;

		SwimComp.LeftStopSwimmingVolume();
		OnStopSwimmingVolumeExited.Broadcast(Player);
	}
}