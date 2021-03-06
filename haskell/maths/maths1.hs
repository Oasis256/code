data Expr = Var Char | Plus Expr Expr | Minus Expr Expr
		| Equals Expr Expr
		| Square Expr
		| Sqrt Expr

c1 = Equals (Plus (Var 'A') (Var 'B')) (Var 'C')
r1 = Equals (Var 'B') (Minus (Var 'C') (Var 'A'))
rule1 = (c1,r1)
c2 = Equals (Square (Var 'A')) (Var 'B')
r2 = Equals (Var 'A') (Sqrt (Var 'B'))
rule2 = (c2,r2)

sit1 = Equals (Plus (Square (Var 'x')) (Square (Var 'y'))) (Square
		(Var 'z'))

go = disp sit1 >> nl >> disp sit2 >> nl >> disp sit3
sit2 = apply rule1 sit1
sit3 = apply rule2 sit2
nl = putStr("\n")

apply (c,r) s = recon r (fits c s)

disp :: Expr -> IO()
disp (Var a) = putChar(a)
disp (Plus a b) = disp a >> putChar('+') >> disp b
disp (Minus a b) = disp a >> putChar('-') >> disp b
disp (Equals a b) = disp a >> putChar('=') >> disp b
disp (Square a) = disp a >> putStr("^2")
disp (Sqrt a) = putStr("root(") >> disp a >> putStr(")")

fits :: Expr -> Expr -> [(Char,Expr)]
fits (Equals a b) (Equals c d) = (fits a c)++(fits b d)
fits (Plus a b) (Plus c d) = (fits a c)++(fits b d)
fits (Minus a b) (Minus c d) = (fits a c)++(fits b d)
fits (Square a) (Square b) = fits a b
fits (Sqrt a) (Sqrt b) = fits a b
fits (Var a) b = [(a,b)]
--fits a b = False

recon :: Expr -> [(Char,Expr)] -> Expr
recon (Equals a b) f = Equals (recon a f) (recon b f)
recon (Plus a b) f = Plus (recon a f) (recon b f)
recon (Minus a b) f = Minus (recon a f) (recon b f)
recon (Square a) f = Square (recon a f)
recon (Sqrt a) f = Sqrt (recon a f)
recon (Var a) f = accomp a f

accomp :: Char -> [(Char,Expr)] -> Expr
accomp a ((b,c):rest) = if (b==a) then
				c
			else
				(accomp (a) (rest))
