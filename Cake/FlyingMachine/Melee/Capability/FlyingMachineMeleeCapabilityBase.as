
import Cake.FlyingMachine.Melee.FlyingMachineMeleeComponent;
import Cake.FlyingMachine.Melee.MeleeTags;



class UFlyingMachineMeleeCapabilityBase : UHazeMelee2DCapabilityBase
{
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	
	default CapabilityDebugCategory = MeleeTags::Melee;
}
