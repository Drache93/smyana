// What Creel asks a game to define: the hook points its sim calls. Smyana's own rules (needs, the season, wolves)
// will come in here; for now they do nothing, which is a valid game.

def packs_loaded(root:string): return

def hook_declare(): return

def hook_on_hit(by:int, target:int, damage:int) -> int: return damage

def hook_on_hurt(target:int, by:int): return

def hook_on_death(i:int, killer:int): return

def hook_unit_tick(i:int): return

def hook_on_order(code:int, p:int, ids:[int], x:int, y:int): return

def hook_ai_train_score(p:int, slot:string, k:int, score:int) -> int: return score
