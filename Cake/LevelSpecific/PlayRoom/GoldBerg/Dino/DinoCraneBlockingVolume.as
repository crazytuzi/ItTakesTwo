
class ADinoCraneBlockingVolume : AVolume
{
	default BrushComponent.SetCollisionProfileName(n"Custom");
	default BrushComponent.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default BrushComponent.SetCollisionObjectType(ECollisionChannel::ECC_Vehicle);
	default BrushComponent.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BrushComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Vehicle, ECollisionResponse::ECR_Block);
}