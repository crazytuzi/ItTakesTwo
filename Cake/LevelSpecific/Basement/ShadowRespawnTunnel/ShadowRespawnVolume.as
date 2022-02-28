import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ShadowRespawnTunnel.ShadowRespawnTunnel;

class AShadowRespawnVolume : AVolume
{
	default BrushComponent.SetCollisionProfileName(n"Trigger");
	default Shape::SetVolumeBrushColor(this, FLinearColor::DPink);

	AShadowRespawnTunnel ShadowTunnel;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		TArray<AShadowRespawnTunnel> Tunnels;
		GetAllActorsOfClass(Tunnels);

		if (Tunnels.Num() == 0)
			Print("PLEASE PLACE SHADOW RESPAWN TUNNEL IN LEVEL");
		else
			ShadowTunnel = Tunnels[0];

		BrushComponent.OnComponentBeginOverlap.AddUFunction(this, n"BrushBeginOverlap");
	}

	UFUNCTION()
	void BrushBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AParentBlob ParentBlob = Cast<AParentBlob>(OtherActor);
		if (ParentBlob == nullptr)
			return;

		if (ShadowTunnel == nullptr)
			return;

		ShadowTunnel.ActivateShadowTunnel();
	}
}