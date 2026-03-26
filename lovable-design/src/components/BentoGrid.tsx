import { motion } from "framer-motion";
import { Link } from "react-router-dom";
import { modules } from "@/data/modules";

const container = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { staggerChildren: 0.1 },
  },
};

const item = {
  hidden: { opacity: 0, y: 30 },
  show: { opacity: 1, y: 0, transition: { duration: 0.5 } },
};

const spanMap: Record<string, string> = {
  "cleaning": "md:col-span-2",
  "serwis": "md:col-span-2",
};

export function BentoGrid() {
  return (
    <section id="ecosystem" className="py-24 px-4">
      <div className="container mx-auto max-w-6xl">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="font-display text-3xl md:text-5xl font-bold mb-4">
            Ekosystem <span className="gradient-brand-text">DOMIO</span>
          </h2>
          <p className="text-muted-foreground text-lg max-w-md mx-auto">
            Modularna platforma, którą dopasowujesz do swoich potrzeb.
          </p>
        </motion.div>

        <motion.div
          variants={container}
          initial="hidden"
          whileInView="show"
          viewport={{ once: true, amount: 0.2 }}
          className="grid grid-cols-1 md:grid-cols-3 gap-4"
        >
          {modules.map((mod) => {
            const Icon = mod.icon;
            const span = spanMap[mod.slug] || "";
            const card = (
              <motion.div
                key={mod.slug}
                variants={item}
                whileHover={mod.comingSoon ? {} : { y: -6, scale: 1.02 }}
                className={`${mod.comingSoon ? "bento-card-disabled" : "bento-card"} ${span}`}
              >
                <div className="flex items-start gap-4">
                  <div className={`p-3 rounded-xl bg-muted ${mod.color}`}>
                    <Icon className="h-6 w-6" />
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="font-display font-semibold text-lg">{mod.name}</h3>
                      {mod.comingSoon && (
                        <span className="text-xs bg-muted text-muted-foreground px-2 py-0.5 rounded-full">
                          Wkrótce
                        </span>
                      )}
                    </div>
                    <p className="text-sm text-muted-foreground">{mod.description}</p>
                  </div>
                </div>
              </motion.div>
            );

            if (mod.comingSoon) return <div key={mod.slug}>{card}</div>;
            return (
              <Link key={mod.slug} to={`/module/${mod.slug}`} className={span}>
                {card}
              </Link>
            );
          })}
        </motion.div>
      </div>
    </section>
  );
}
